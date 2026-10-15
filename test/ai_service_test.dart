import 'dart:convert';

import 'package:aman_sarthi/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('uses the verified Render backend URL by default', () {
    final service = AiService.fromEnvironment();
    addTearDown(service.close);

    expect(service.baseUrl, 'https://aman-sarthi.onrender.com');
  });

  test(
    'backend streams generated text and omits client-controlled system turns',
    () async {
      late Map<String, dynamic> requestBody;
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://api.example.test/api/chat');
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          'data: {"type":"delta","text":"A real "}\n\n'
          'data: {"type":"delta","text":"answer."}\n\n'
          'data: {"type":"done"}\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final service = AiService.backend(
        baseUrl: 'https://api.example.test/',
        client: client,
      );
      addTearDown(service.close);

      final answer = await service.streamReply([
        const ChatTurn(role: 'system', content: 'client system prompt'),
        const ChatTurn(role: 'user', content: 'Explain this.'),
      ]).join();

      expect(answer, 'A real answer.');
      expect(requestBody['messages'], [
        {'role': 'user', 'content': 'Explain this.'},
      ]);
      expect(requestBody['stream'], isTrue);
    },
  );

  test(
    'debug backend accepts a private LAN URL for physical devices',
    () async {
      final service = AiService.backend(
        baseUrl: 'http://192.168.1.20:8080',
        client: MockClient((request) async {
          expect(request.url.toString(), 'http://192.168.1.20:8080/api/chat');
          return http.Response(
            'data: {"type":"delta","text":"Ready."}\n\n'
            'data: {"type":"done"}\n\n',
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }),
      );
      addTearDown(service.close);

      final answer = await service.streamReply([
        const ChatTurn(role: 'user', content: 'Hello'),
      ]).join();

      expect(answer, 'Ready.');
    },
  );

  test('debug backend rejects public HTTP URLs', () async {
    final service = AiService.backend(
      baseUrl: 'http://example.com',
      client: MockClient(
        (_) async => fail('Public HTTP must not be requested.'),
      ),
    );
    addTearDown(service.close);

    await expectLater(
      service.streamReply([
        const ChatTurn(role: 'user', content: 'Hello'),
      ]).toList(),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          contains('HTTPS'),
        ),
      ),
    );
  });

  test('missing backend URL fails clearly without making a request', () async {
    final client = MockClient((_) async {
      fail('No request should be made without a backend URL.');
    });
    final service = AiService.backend(baseUrl: '', client: client);
    addTearDown(service.close);

    await expectLater(
      service.streamReply([
        const ChatTurn(role: 'user', content: 'Hello'),
      ]).toList(),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          contains('AI_API_BASE_URL'),
        ),
      ),
    );
  });

  test(
    'connection test confirms backend readiness without reading secrets',
    () async {
      late http.Request readinessRequest;
      final service = AiService.backend(
        baseUrl: 'https://api.example.test/',
        client: MockClient((request) async {
          readinessRequest = request;
          return http.Response(
            '{"ready":true}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(service.close);

      await service.testConnection();

      expect(readinessRequest.method, 'GET');
      expect(
        readinessRequest.url.toString(),
        'https://api.example.test/readyz',
      );
    },
  );

  test(
    'connection test clearly rejects a build without a backend URL',
    () async {
      final client = MockClient((_) async {
        fail('No request should be made without a backend URL.');
      });
      final service = AiService.backend(baseUrl: '', client: client);
      addTearDown(service.close);

      await expectLater(
        service.testConnection(),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.message,
            'message',
            contains('AI_API_BASE_URL'),
          ),
        ),
      );
    },
  );

  test(
    'connection test explains when provider configuration is missing',
    () async {
      final service = AiService.backend(
        baseUrl: 'https://api.example.test',
        client: MockClient((_) async => http.Response('{"ready":false}', 503)),
      );
      addTearDown(service.close);

      await expectLater(
        service.testConnection(),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.message,
            'message',
            contains('GEMINI_API_KEY'),
          ),
        ),
      );
    },
  );

  test('provider error events surface a safe retryable message', () async {
    final service = AiService.backend(
      baseUrl: 'https://api.example.test',
      client: MockClient(
        (_) async => http.Response(
          'event: error\n'
          'data: {"type":"error","code":"provider_rate_limited",'
          '"message":"The AI provider is busy. Try again shortly.",'
          '"status":429}\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        ),
      ),
    );
    addTearDown(service.close);

    await expectLater(
      service.streamReply([
        const ChatTurn(role: 'user', content: 'Hello'),
      ]).toList(),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          contains('provider is busy'),
        ),
      ),
    );
  });
}
