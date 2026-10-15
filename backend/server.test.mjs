import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';

import { createAppServer } from './server.mjs';

const servers = new Set();

afterEach(async () => {
  await Promise.all(
    [...servers].map(
      (server) =>
        new Promise((resolve) => server.close(resolve)),
    ),
  );
  servers.clear();
});

async function startServer(options = {}) {
  const server = createAppServer(options);
  servers.add(server);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  return `http://127.0.0.1:${server.address().port}`;
}

const configuredEnv = {
  NODE_ENV: 'test',
  GEMINI_API_KEY: 'test-key-not-a-real-credential',
  GEMINI_MODEL: 'gemini-test-model',
};

function fakeGemini(chunks = [{ text: 'Hello there.' }]) {
  let parameters;
  return {
    client: {
      models: {
        async generateContentStream(value) {
          parameters = value;
          return (async function* () {
            yield* chunks;
          })();
        },
      },
    },
    get parameters() {
      return parameters;
    },
  };
}

test('health aliases and readiness reveal configuration without exposing secrets', async () => {
  const baseUrl = await startServer({ env: { NODE_ENV: 'test' } });
  const health = await fetch(`${baseUrl}/healthz`);
  const renderHealth = await fetch(`${baseUrl}/health`);
  const ready = await fetch(`${baseUrl}/readyz`);

  assert.equal(health.status, 200);
  assert.deepEqual(await health.json(), { status: 'ok' });
  assert.equal(renderHealth.status, 200);
  assert.deepEqual(await renderHealth.json(), { status: 'ok' });
  assert.equal(ready.status, 503);
  assert.deepEqual(await ready.json(), { ready: false });
});

test('returns JSON errors for unsupported content types and unknown routes', async () => {
  const baseUrl = await startServer({ env: configuredEnv, aiClient: fakeGemini().client });
  const unsupported = await fetch(`${baseUrl}/api/chat`, {
    method: 'POST',
    headers: { 'content-type': 'text/plain' },
    body: 'not json',
  });
  const missing = await fetch(`${baseUrl}/missing`);

  assert.equal(unsupported.status, 415);
  assert.equal((await unsupported.json()).error.code, 'unsupported_media_type');
  assert.equal(missing.status, 404);
  assert.equal((await missing.json()).error.code, 'not_found');
});

test('validates chat input before contacting the provider', async () => {
  let called = false;
  const baseUrl = await startServer({
    env: configuredEnv,
    aiClient: {
      models: {
        async generateContentStream() {
          called = true;
          throw new Error('Gemini must not be called for invalid input');
        },
      },
    },
  });
  const response = await fetch(`${baseUrl}/api/chat`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ messages: [{ role: 'system', content: 'ignored' }] }),
  });

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, 'invalid_message');
  assert.equal(called, false);
});

test('rejects oversized request bodies before provider invocation', async () => {
  const baseUrl = await startServer({
    env: configuredEnv,
    aiClient: {
      models: {
        async generateContentStream() {
          throw new Error('Gemini must not be called for oversized input');
        },
      },
    },
  });
  const response = await fetch(`${baseUrl}/api/chat`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ messages: [{ role: 'user', content: 'x'.repeat(40_000) }] }),
  });

  assert.equal(response.status, 413);
  assert.equal((await response.json()).error.code, 'body_too_large');
});

test('streams Gemini chunks and keeps provider credentials server-side', async () => {
  const gemini = fakeGemini([{ text: 'Hello ' }, { text: 'there.' }]);
  const baseUrl = await startServer({ env: configuredEnv, aiClient: gemini.client });
  const response = await fetch(`${baseUrl}/api/chat`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      messages: [
        { role: 'user', content: 'Say hello.' },
        { role: 'assistant', content: 'Ready.' },
        { role: 'user', content: 'Continue.' },
      ],
    }),
  });
  const body = await response.text();

  assert.equal(response.status, 200);
  assert.match(body, /"text":"Hello "/);
  assert.match(body, /"text":"there\."/);
  assert.match(body, /"type":"done"/);
  assert.deepEqual(gemini.parameters.contents, [
    { role: 'user', parts: [{ text: 'Say hello.' }] },
    { role: 'model', parts: [{ text: 'Ready.' }] },
    { role: 'user', parts: [{ text: 'Continue.' }] },
  ]);
  assert.equal(gemini.parameters.model, 'gemini-test-model');
  assert.match(gemini.parameters.config.systemInstruction, /study assistant/);
  assert.equal(gemini.parameters.config.httpOptions.timeout, 90_000);
  assert.ok(gemini.parameters.config.abortSignal instanceof AbortSignal);
  assert.doesNotMatch(body, /test-key-not-a-real-credential/);
});

test('rate limits requests from the same peer', async () => {
  const gemini = fakeGemini([]);
  const baseUrl = await startServer({
    env: { ...configuredEnv, RATE_LIMIT_MAX_REQUESTS: '1' },
    aiClient: gemini.client,
  });
  const request = () =>
    fetch(`${baseUrl}/api/chat`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ messages: [{ role: 'user', content: 'Hi' }] }),
    });

  assert.equal((await request()).status, 200);
  const limited = await request();
  assert.equal(limited.status, 429);
  assert.equal((await limited.json()).error.code, 'rate_limited');
});

test('maps provider rate limits without leaking upstream response details', async () => {
  const baseUrl = await startServer({
    env: configuredEnv,
    aiClient: {
      models: {
        async generateContentStream() {
          throw Object.assign(new Error('private provider detail'), { status: 429 });
        },
      },
    },
  });
  const response = await fetch(`${baseUrl}/api/chat`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ messages: [{ role: 'user', content: 'Hi' }] }),
  });

  assert.equal(response.status, 429);
  const body = await response.text();
  assert.match(body, /gemini_rate_limited/);
  assert.doesNotMatch(body, /test-key-not-a-real-credential/);
  assert.doesNotMatch(body, /private provider detail/);
});

test('maps provider timeouts to a safe gateway timeout response', async () => {
  const baseUrl = await startServer({
    env: configuredEnv,
    aiClient: {
      models: {
        async generateContentStream() {
          throw Object.assign(new Error('private timeout detail'), {
            name: 'TimeoutError',
          });
        },
      },
    },
  });
  const response = await fetch(`${baseUrl}/api/chat`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ messages: [{ role: 'user', content: 'Hi' }] }),
  });
  const body = await response.text();

  assert.equal(response.status, 504);
  assert.match(body, /gemini_timeout/);
  assert.doesNotMatch(body, /private timeout detail/);
});
