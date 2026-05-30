class StepItem {
  int stepOrder;
  String description;
  int estimatedMin;

  StepItem({
    this.stepOrder = 1,
    this.description = "",
    this.estimatedMin = 0,
  });

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
  String status;
  String? quadrant;
  String? scheduledDate;
  String? timeSlot;
  int calendarOrder;
  List<StepItem> steps;
  String createdAt;
  String? completedAt;
  String? deletedAt;

  Event({
    this.id,
    this.title = "",
    this.summary = "",
    this.purpose = "",
    this.status = "inbox",
    this.quadrant,
    this.scheduledDate,
    this.timeSlot,
    this.calendarOrder = 0,
    List<StepItem>? steps,
    String? createdAt,
    this.completedAt,
    this.deletedAt,
  })  : steps = steps ?? [],
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] is int ? json['id'] : null,
      title: json['title'] ?? "",
      summary: json['summary'] ?? "",
      purpose: json['purpose'] ?? "",
      status: json['status'] ?? "inbox",
      quadrant: json['quadrant'],
      scheduledDate: json['scheduled_date'],
      timeSlot: json['time_slot'],
      calendarOrder: json['calendar_order'] is int ? json['calendar_order'] : 0,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => StepItem.fromJson(s))
              .toList() ??
          [],
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      completedAt: json['completed_at'],
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'summary': summary,
        'purpose': purpose,
        'status': status,
        'quadrant': quadrant,
        'scheduled_date': scheduledDate,
        'time_slot': timeSlot,
        'calendar_order': calendarOrder,
        'steps': steps.map((s) => s.toJson()).toList(),
        'created_at': createdAt,
        'completed_at': completedAt,
        'deleted_at': deletedAt,
      };

  int get totalMinutes => steps.fold(0, (sum, s) => sum + s.estimatedMin);
}
