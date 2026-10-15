import { randomUUID } from 'node:crypto';
import { createServer } from 'node:http';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

import { GoogleGenAI } from '@google/genai';
import 'dotenv/config';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';

const DEFAULT_MODEL = 'gemini-flash-latest';
const GEMINI_TIMEOUT_MS = 90_000;
const SYSTEM_INSTRUCTION =
  'You are Aman Sarthi, a helpful study assistant. Reply accurately, clearly, and respectfully. ' +
  'Use the language of the learner when practical, including Hindi or English. ' +
  'For mathematics, show a step-by-step solution with the key reasoning and calculations before the final answer. ' +
  'For science, explain concepts and terminology clearly. For English or Hindi, explain language questions with examples when useful. ' +
  'If a question is ambiguous or missing essential information, ask a concise clarifying question rather than inventing details.';

class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

function configuredModel(env) {
  return env.GEMINI_MODEL?.trim() || DEFAULT_MODEL;
}

function isConfigured(env) {
  return Boolean(env.GEMINI_API_KEY?.trim() && configuredModel(env));
}

function validateMessages(value) {
  if (!Array.isArray(value) || value.length === 0 || value.length > 20) {
    throw new ApiError(400, 'invalid_messages', 'Send between 1 and 20 chat messages.');
  }

  let totalLength = 0;
  const messages = value.map((message) => {
    if (
      message === null ||
      typeof message !== 'object' ||
      !['user', 'assistant'].includes(message.role) ||
      typeof message.content !== 'string'
    ) {
      throw new ApiError(
        400,
        'invalid_message',
        'Each message needs a user or assistant role and text content.',
      );
    }

    const content = message.content.trim();
    if (content.length === 0 || content.length > 8000) {
      throw new ApiError(
        400,
        'invalid_message',
        'Each message must contain 1 to 8000 characters.',
      );
    }
    totalLength += content.length;
    return { role: message.role, content };
  });

  if (totalLength > 16000 || messages.at(-1)?.role !== 'user') {
    throw new ApiError(
      400,
      'invalid_messages',
      'The conversation is too long or does not end with a user message.',
    );
  }
  return messages;
}

function providerError(error) {
  const status = Number(error?.status ?? error?.response?.status);
  if (
    error?.name === 'TimeoutError' ||
    error?.name === 'AbortError' ||
    error?.code === 'ETIMEDOUT'
  ) {
    return new ApiError(504, 'gemini_timeout', 'Gemini took too long to respond. Try again.');
  }
  if (status === 429) {
    return new ApiError(429, 'gemini_rate_limited', 'Gemini is busy. Try again shortly.');
  }
  if (status === 401 || status === 403) {
    return new ApiError(
      502,
      'gemini_authentication_failed',
      'Gemini authentication failed. Check GEMINI_API_KEY in the backend environment.',
    );
  }
  return new ApiError(502, 'gemini_error', 'Gemini could not complete this request.');
}

function sendError(response, status, code, message, requestId) {
  response.status(status).json({
    error: { code, message, requestId },
  });
}

export function createAppServer({ env = process.env, aiClient } = {}) {
  const app = express();
  const allowedOrigins = new Set(
    (env.CORS_ORIGINS ?? '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
  );
  const gemini = aiClient ?? (
    env.GEMINI_API_KEY?.trim()
      ? new GoogleGenAI({ apiKey: env.GEMINI_API_KEY.trim() })
      : null
  );

  app.disable('x-powered-by');
  app.set('trust proxy', env.NODE_ENV === 'production' ? 1 : false);
  app.use(helmet());
  app.use((request, response, next) => {
    request.requestId = randomUUID();
    response.setHeader('x-request-id', request.requestId);
    const origin = request.headers.origin;
    const isLocalDevelopmentOrigin =
      env.NODE_ENV === 'development' &&
      /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin ?? '');

    if (origin && !allowedOrigins.has(origin) && !isLocalDevelopmentOrigin) {
      return sendError(
        response,
        403,
        'origin_not_allowed',
        'This origin is not allowed to access the API.',
        request.requestId,
      );
    }
    if (origin) {
      response.setHeader('access-control-allow-origin', origin);
      response.setHeader('vary', 'Origin');
    }
    response.setHeader('access-control-allow-methods', 'GET, POST, OPTIONS');
    response.setHeader('access-control-allow-headers', 'content-type');
    if (request.method === 'OPTIONS') return response.sendStatus(204);
    next();
  });
  app.use(express.json({ limit: '32kb', strict: true }));

  const windowMs = Number(env.RATE_LIMIT_WINDOW_MS ?? 60_000);
  const max = Number(env.RATE_LIMIT_MAX_REQUESTS ?? 20);
  const chatLimiter = rateLimit({
    windowMs: Number.isSafeInteger(windowMs) && windowMs > 0 ? windowMs : 60_000,
    limit: Number.isSafeInteger(max) && max > 0 ? max : 20,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (request, response) =>
      sendError(
        response,
        429,
        'rate_limited',
        'Too many requests. Try again shortly.',
        request.requestId,
      ),
  });

  app.get(['/health', '/healthz'], (_request, response) => {
    response.json({ status: 'ok' });
  });

  app.get('/readyz', (_request, response) => {
    const ready = isConfigured(env);
    response.status(ready ? 200 : 503).json({ ready });
  });

  app.post('/api/chat', chatLimiter, async (request, response) => {
    try {
      if (!isConfigured(env) || !gemini) {
        throw new ApiError(
          503,
          'gemini_not_configured',
          'Gemini is not configured on this server.',
        );
      }
      if (!request.is('application/json')) {
        throw new ApiError(
          415,
          'unsupported_media_type',
          'Content-Type must be application/json.',
        );
      }

      const messages = validateMessages(request.body?.messages);
      const stream = await gemini.models.generateContentStream({
        model: configuredModel(env),
        contents: messages.map((message) => ({
          role: message.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: message.content }],
        })),
        config: {
          systemInstruction: SYSTEM_INSTRUCTION,
          httpOptions: { timeout: GEMINI_TIMEOUT_MS },
          abortSignal: AbortSignal.timeout(GEMINI_TIMEOUT_MS),
        },
      });

      response.status(200);
      response.setHeader('content-type', 'text/event-stream; charset=utf-8');
      response.setHeader('cache-control', 'no-cache, no-transform');
      response.setHeader('connection', 'keep-alive');
      response.setHeader('x-accel-buffering', 'no');
      response.flushHeaders();

      try {
        for await (const chunk of stream) {
          if (response.destroyed) return;
          if (typeof chunk.text === 'string' && chunk.text.length > 0) {
            response.write(`data: ${JSON.stringify({ type: 'delta', text: chunk.text })}\n\n`);
          }
        }
        if (!response.destroyed) response.write('data: {"type":"done"}\n\n');
      } catch (error) {
        const safeError = providerError(error);
        if (!response.destroyed) {
          response.write(
            `event: error\ndata: ${JSON.stringify({
              type: 'error',
              code: safeError.code,
              message: safeError.message,
              status: safeError.status,
            })}\n\n`,
          );
        }
      }
      if (!response.destroyed) response.end();
    } catch (error) {
      const safeError = error instanceof ApiError
        ? error
        : providerError(error);
      if (!response.headersSent) {
        sendError(
          response,
          safeError.status,
          safeError.code,
          safeError.message,
          request.requestId,
        );
      } else if (!response.destroyed) {
        response.end();
      }
    }
  });

  app.use((request, response) => {
    sendError(
      response,
      404,
      'not_found',
      'Route not found.',
      request.requestId,
    );
  });

  app.use((error, request, response, _next) => {
    if (response.headersSent) return response.end();
    if (error?.type === 'entity.too.large') {
      return sendError(response, 413, 'body_too_large', 'Request body is too large.', request.requestId);
    }
    if (error instanceof SyntaxError && 'body' in error) {
      return sendError(response, 400, 'invalid_json', 'Request body must be valid JSON.', request.requestId);
    }
    return sendError(
      response,
      500,
      'internal_error',
      'The request could not be completed.',
      request.requestId,
    );
  });

  return createServer(app);
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  const server = createAppServer();
  const port = Number(process.env.PORT ?? 8080);
  const host = process.env.HOST ?? '0.0.0.0';
  server.listen(port, host, () => {
    console.log(`Aman Sarthi AI API listening on ${host}:${port}`);
  });
}