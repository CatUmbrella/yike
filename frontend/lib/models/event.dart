class StepItem {
  int stepOrder;
  String description;
  int estimatedMin;

  StepItem({this.stepOrder = 1, this.description = "", this.estimatedMin = 0});

  factory StepItem.fromJson(Map<String, dynamic> json) {
    return StepItem(
      stepOrder: json['step_order'] ?? 1,
      description: json['description'] ?? "",
      estimatedMin: json['estimated_min'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'step_order': stepOrder,
    'description': description,
    'estimated_min': estimatedMin,
  };
}

class Event {
  int? id;
  String title;
  String summary;
  String purpose;
  String review;
  String status;
  String? quadrant;
  String? scheduledDate;
  String? timeSlot;
  int calendarOrder;
  List<StepItem> steps;
  int? totalMinutesOverride;
  String createdAt;
  String? completedAt;
  String? deletedAt;

  Event({
    this.id,
    this.title = "",
    this.summary = "",
    this.purpose = "",
    this.review = "",
    this.status = "inbox",
    this.quadrant,
    this.scheduledDate,
    this.timeSlot,
    this.calendarOrder = 0,
    List<StepItem>? steps,
    this.totalMinutesOverride,
    String? createdAt,
    this.completedAt,
    this.deletedAt,
  }) : steps = steps ?? [],
       createdAt = _normalizedDateText(createdAt);

  factory Event.fromJson(Map<String, dynamic> json) {
    final totalMinutes = _intFromJson(json['total_minutes']);
    return Event(
      id: _intFromJson(json['id']),
      title: json['title'] ?? "",
      summary: json['summary'] ?? "",
      purpose: json['purpose'] ?? "",
      review: json['review'] ?? "",
      status: json['status'] ?? "inbox",
      quadrant: json['quadrant'],
      scheduledDate: json['scheduled_date'],
      timeSlot: json['time_slot'],
      calendarOrder: _intFromJson(json['calendar_order']) ?? 0,
      totalMinutesOverride: totalMinutes != null && totalMinutes > 0
          ? totalMinutes
          : null,
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((s) => StepItem.fromJson(s))
              .toList() ??
          [],
      createdAt: _normalizedDateText(
        json['created_at'],
        fallback: json['updated_at'],
      ),
      completedAt: json['completed_at'],
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'title': title,
    'summary': summary,
    'purpose': purpose,
    'review': review,
    'status': status,
    'quadrant': quadrant,
    'scheduled_date': scheduledDate,
    'time_slot': timeSlot,
    'calendar_order': calendarOrder,
    'steps': steps.map((s) => s.toJson()).toList(),
    if (totalMinutesOverride != null) 'total_minutes': totalMinutesOverride,
    'created_at': createdAt,
    'completed_at': completedAt,
    'deleted_at': deletedAt,
  };

  // `totalMinutesOverride` stores a manually adjusted total, or an AI-provided
  // total when the backend returns only aggregate duration.
  int get totalMinutes =>
      totalMinutesOverride ?? steps.fold(0, (sum, s) => sum + s.estimatedMin);
}

int? _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _normalizedDateText(Object? value, {Object? fallback}) {
  return _validDateText(value) ??
      _validDateText(fallback) ??
      DateTime.now().toIso8601String();
}

String? _validDateText(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  if (text.isEmpty || DateTime.tryParse(text) == null) return null;
  return text;
}
