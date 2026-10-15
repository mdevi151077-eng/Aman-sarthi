import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

bool _isPrivateIpv4Host(String host) {
  final octets = host.split('.').map(int.tryParse).toList();
  if (octets.length != 4 ||
      octets.any((octet) => octet == null || octet < 0 || octet > 255)) {
    return false;
  }

  final first = octets[0]!;
  final second = octets[1]!;
  return first == 10 ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168);
}

bool _isAllowedDebugHttpHost(String host) =>
    host == 'localhost' ||
    host == '127.0.0.1' ||
    host == '10.0.2.2' ||
    _isPrivateIpv4Host(host);

class ChatTurn {
  const ChatTurn({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AiServiceException implements Exception {
  const AiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiService {
  AiService._({
    required this.provider,
    required this.baseUrl,
    required this.client,
    this.configurationError,
  });

  factory AiService.backend({required String baseUrl, http.Client? client}) =>
      AiService._(
        provider: 'backend',
        baseUrl: baseUrl.trim().replaceFirst(RegExp(r'/$'), ''),
        client: client ?? http.Client(),
      );

  factory AiService.localOllamaForDevelopment({
    required String baseUrl,
    http.Client? client,
  }) => AiService._(
    provider: 'ollama',
    baseUrl: baseUrl.trim().replaceFirst(RegExp(r'/$'), ''),
    client: client ?? http.Client(),
    configurationError: kDebugMode
        ? null
        : const AiServiceException(
            'Direct Ollama mode is for development only. Configure an HTTPS '
            'AI_API_BASE_URL for a released app.',
          ),
  );

  factory AiService.fromEnvironment({http.Client? client}) {
    const provider = String.fromEnvironment(
      'AI_PROVIDER',
      defaultValue: 'backend',
    );
    const apiBaseUrl = String.fromEnvironment(
      'AI_API_BASE_URL',
      defaultValue: 'https://aman-sarthi.onrender.com',
    );
    const ollamaBaseUrl = String.fromEnvironment('OLLAMA_BASE_URL');

    if (provider == 'backend') {
      return AiService.backend(baseUrl: apiBaseUrl, client: client);
    }
    if (provider != 'ollama') {
      return AiService._(
        provider: 'backend',
        baseUrl: '',
        client: client ?? http.Client(),
        configurationError: const AiServiceException(
          'AI_PROVIDER must be backend or ollama.',
        ),
      );
    }

    final baseUrl = ollamaBaseUrl.isNotEmpty
        ? ollamaBaseUrl.trim().replaceFirst(RegExp(r'/$'), '')
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:11434'
        : 'http://127.0.0.1:11434';
    return AiService.localOllamaForDevelopment(
      baseUrl: baseUrl,
      client: client,
    );
  }

  final String provider;
  final String baseUrl;
  final http.Client client;
  final AiServiceException? configurationError;

  Future<void> testConnection() async {
    if (configurationError case final error?) throw error;
    if (provider != 'backend') {
      throw const AiServiceException(
        'Connection testing is available for the hosted AI backend.',
      );
    }
    if (baseUrl.isEmpty) {
      throw const AiServiceException(
        'This app build has no AI_API_BASE_URL. Set it to your deployed '
        'HTTPS backend URL when building the app.',
      );
    }

    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' &&
            !(kDebugMode && _isAllowedDebugHttpHost(uri.host)))) {
      throw const AiServiceException(
        'The AI API address must use HTTPS. Local HTTP is permitted only '
        'while debugging.',
      );
    }

    late http.Response response;
    try {
      response = await client
          .get(Uri.parse('$baseUrl/readyz'))
          .timeout(const Duration(seconds: 100));
    } on TimeoutException {
      throw const AiServiceException(
        'AI backend connection timed out. A free service may be waking up; '
        'please try again.',
      );
    } on Exception {
      throw const AiServiceException(
        'Could not reach the AI backend. Check the deployed URL and internet '
        'connection.',
      );
    }

    if (response.statusCode == 503) {
      throw const AiServiceException(
        'The backend is online but Gemini is not configured. Set '
        'GEMINI_API_KEY in the backend environment.',
      );
    }
    if (response.statusCode != 200) {
      throw AiServiceException(
        'AI backend readiness check failed (${response.statusCode}).',
      );
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['ready'] == true) return;
    } on FormatException {
      throw const AiServiceException(
        'AI backend returned an invalid readiness response.',
      );
    }
    throw const AiServiceException(
      'AI backend responded but is not ready to generate replies.',
    );
  }

  Stream<String> streamReply(List<ChatTurn> messages) async* {
    if (configurationError case final error?) throw error;
    if (provider == 'backend' && baseUrl.isEmpty) {
      throw const AiServiceException(
        'This app build has no AI_API_BASE_URL. Set it to your deployed '
        'HTTPS backend URL when building the app.',
      );
    }
    if (baseUrl.isNotEmpty) {
      final uri = Uri.tryParse(baseUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' &&
              !(kDebugMode && _isAllowedDebugHttpHost(uri.host)))) {
        throw const AiServiceException(
          'The AI API address must use HTTPS. Local HTTP is permitted only '
          'while debugging.',
        );
      }
    }

    final conversation = messages
        .where((message) => provider == 'ollama' || message.role != 'system')
        .toList();
    while (conversation.length > 20 ||
        conversation.fold<int>(
              0,
              (length, message) => length + message.content.length,
            ) >
            16000) {
      if (conversation.length <= 1) {
        throw const AiServiceException(
          'Is sawaal ki length AI request limit se zyada hai.',
        );
      }
      conversation.removeAt(0);
    }
    if (conversation.isEmpty || conversation.last.role != 'user') {
      throw const AiServiceException(
        'AI request mein aakhri message user ka hona chahiye.',
      );
    }

    final request = http.Request('POST', Uri.parse('$baseUrl/api/chat'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({
        if (provider == 'ollama') 'model': 'llama3.2:1b',
        'messages': conversation.map((message) => message.toJson()).toList(),
        'stream': true,
      });

    http.StreamedResponse response;
    try {
      response = await client
          .send(request)
          .timeout(const Duration(seconds: 100));
    } on TimeoutException {
      throw const AiServiceException(
        'AI server response lene mein bahut samay laga. Dobara koshish karein.',
      );
    } on Exception {
      throw const AiServiceException(
        'AI server se sampark nahi ho saka. Internet aur backend URL check karein.',
      );
    }

    if (response.statusCode != 200) {
      final body = await response.stream
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));
      final details = _readError(body);
      if (response.statusCode == 429) {
        throw AiServiceException(
          details ?? 'Bahut zyada requests. Thodi der baad koshish karein.',
        );
      }
      if (response.statusCode == 503) {
        throw AiServiceException(
          details ?? 'Online AI backend configure nahi hua hai.',
        );
      }
      throw AiServiceException(
        details ?? 'AI server error (${response.statusCode}).',
      );
    }

    try {
      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .timeout(const Duration(seconds: 100))) {
        if (line.startsWith('data:')) {
          final data = line.substring(5).trim();
          if (data.isEmpty) continue;
          final payload = jsonDecode(data);
          if (payload is! Map<String, dynamic>) {
            throw const AiServiceException(
              'AI server ne galat response bheja.',
            );
          }
          if (payload['type'] == 'error') {
            throw AiServiceException(
              payload['message'] as String? ??
                  'AI provider response nahi de saka.',
            );
          }
          if (payload['type'] == 'done') return;
          if (payload['type'] == 'delta' && payload['text'] is String) {
            yield payload['text'] as String;
            continue;
          }
          final message = payload['message'];
          if (message is Map<String, dynamic> && message['content'] is String) {
            yield message['content'] as String;
          }
          continue;
        }

        if (provider == 'ollama' && line.trim().isNotEmpty) {
          final payload = jsonDecode(line);
          if (payload is! Map<String, dynamic>) {
            throw const AiServiceException('Ollama ne galat response bheja.');
          }
          if (payload['error'] is String) {
            throw AiServiceException(payload['error'] as String);
          }
          final message = payload['message'];
          if (message is Map<String, dynamic> && message['content'] is String) {
            yield message['content'] as String;
          }
        }
      }
    } on TimeoutException {
      throw const AiServiceException(
        'AI response stream ruk gaya. Dobara koshish karein.',
      );
    } on FormatException {
      throw const AiServiceException(
        'AI server ne padhne yogya response nahi bheja.',
      );
    }
  }

  String? _readError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
        if (error is String) return error;
      }
    } on FormatException {
      // Non-JSON upstream responses are replaced with a safe status message.
    }
    return null;
  }

  void close() => client.close();
}
