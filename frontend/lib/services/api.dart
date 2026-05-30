import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  static Future<List<Event>> parseEventText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/events/parse'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final list = data['events'] as List<dynamic>? ?? [];
      return list.map((e) => Event.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

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
