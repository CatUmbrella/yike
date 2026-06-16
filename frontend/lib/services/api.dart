import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event.dart';
import '../models/template_models.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
  static const String _apiToken = String.fromEnvironment('API_TOKEN');
  static const bool _templateBackendEnabled = bool.fromEnvironment(
    'TEMPLATE_BACKEND_ENABLED',
    defaultValue: false,
  );

  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    if (_apiToken.isNotEmpty) 'X-API-Key': _apiToken,
  };

  static Future<ParseEventResult> parseEventText(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/events/parse'),
            headers: _jsonHeaders,
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 120));

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
        headers: _jsonHeaders,
        body: jsonEncode(event.toJson()),
      );

      if (response.statusCode != 200) return null;
      return Event.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  static Future<List<TaskTemplate>?> fetchOfficialTemplates() async {
    if (!_templateBackendEnabled) return null;

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/templates/official'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final list = data is List
          ? data
          : data is Map<String, dynamic>
          ? data['templates'] as List<dynamic>? ?? const []
          : const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(_templateFromJson)
          .toList(growable: false);
    } on TimeoutException {
      return null;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static TaskTemplate _templateFromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return TaskTemplate(
      id: _intValue(json['id']),
      name: (json['name'] as String?) ?? '',
      goal: (json['goal'] as String?) ?? '',
      source: TemplateSource.official,
      status: TemplateStatus.published,
      relation: _relationFromJson(json['relation']),
      currentCreateStep: 4,
      currentStageIndex: 0,
      createCompleted: true,
      stages:
          (json['stages'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(_stageFromJson)
              .toList() ??
          const [],
      notices:
          (json['notices'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(_noticeFromJson)
              .toList() ??
          const [],
      createdAt: _dateValue(json['created_at']) ?? now,
      updatedAt: _dateValue(json['updated_at']) ?? now,
      publishedAt: _dateValue(json['published_at']),
    );
  }

  static TemplateStage _stageFromJson(Map<String, dynamic> json) {
    return TemplateStage(
      id: _intValue(json['id']),
      stageOrder: _intValue(json['stage_order']) ?? 1,
      name: (json['name'] as String?) ?? '',
      goal: (json['goal'] as String?) ?? '',
      estimatedMinutes: _intValue(json['estimated_minutes']) ?? 0,
      events:
          (json['events'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(_stageEventFromJson)
              .toList() ??
          const [],
    );
  }

  static TemplateStageEvent _stageEventFromJson(Map<String, dynamic> json) {
    return TemplateStageEvent(
      id: _intValue(json['id']),
      eventOrder: _intValue(json['event_order']) ?? 1,
      title: (json['title'] as String?) ?? '',
      purpose: (json['purpose'] as String?) ?? '',
      estimatedMinutes: _intValue(json['estimated_minutes']) ?? 0,
      steps:
          (json['steps'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(_stageEventStepFromJson)
              .toList() ??
          const [],
    );
  }

  static TemplateStageEventStep _stageEventStepFromJson(
    Map<String, dynamic> json,
  ) {
    return TemplateStageEventStep(
      id: _intValue(json['id']),
      stepOrder: _intValue(json['step_order']) ?? 1,
      description: (json['description'] as String?) ?? '',
      estimatedMinutes: _intValue(json['estimated_minutes']) ?? 0,
    );
  }

  static TemplateNotice _noticeFromJson(Map<String, dynamic> json) {
    return TemplateNotice(
      id: _intValue(json['id']),
      noticeOrder: _intValue(json['notice_order']) ?? 1,
      content: (json['content'] as String?) ?? '',
    );
  }

  static TemplateRelation? _relationFromJson(Object? value) {
    return switch (value) {
      'linear' => TemplateRelation.linear,
      'parallel' => TemplateRelation.parallel,
      _ => null,
    };
  }

  static DateTime? _dateValue(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
