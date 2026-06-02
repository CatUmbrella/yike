import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static Future<ParseEventResult> parseEventText(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/events/parse'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return ParseEventResult.failure('AI 服务异常，请稍后重试');
      }

      final data = jsonDecode(response.body);
      final list = data['events'] as List<dynamic>? ?? [];
      return ParseEventResult.success(
        list.map((e) => Event.fromJson(e)).toList(),
      );
    } on TimeoutException {
      return ParseEventResult.failure('网络连接超时，请检查服务状态');
    } on FormatException {
      return ParseEventResult.failure('AI 返回格式异常，请稍后重试');
    } catch (_) {
      return ParseEventResult.failure('网络连接失败，请检查服务状态');
    }
  }

  // TODO: Keep as the future cloud-sync entry. Local persistence currently uses
  // LocalDatabase.saveEvent.
  static Future<Event?> createEvent(Event event) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(event.toJson()),
      );

      if (response.statusCode != 200) return null;
      return Event.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }
}

class ParseEventResult {
  final List<Event> events;
  final String? errorText;

  const ParseEventResult._({required this.events, this.errorText});

  const ParseEventResult.success(List<Event> events) : this._(events: events);

  const ParseEventResult.failure(String errorText)
    : this._(events: const [], errorText: errorText);

  bool get failed => errorText != null;
}
