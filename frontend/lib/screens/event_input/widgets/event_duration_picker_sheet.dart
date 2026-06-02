import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../event_input_style.dart';

Future<int?> showEventDurationPickerSheet({
  required BuildContext context,
  required int initialMinutes,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) {
      return EventDurationPickerSheet(initialMinutes: initialMinutes);
    },
  );
}

class EventDurationPickerSheet extends StatefulWidget {
  const EventDurationPickerSheet({super.key, required this.initialMinutes});

  final int initialMinutes;

  @override
  State<EventDurationPickerSheet> createState() =>
      _EventDurationPickerSheetState();
}

class _EventDurationPickerSheetState extends State<EventDurationPickerSheet> {
  static const _hourCount = 25;
  static const _minuteValues = [
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
    60,
  ];

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMinutes.clamp(0, 1500);
    _selectedHour = (initial ~/ 60).clamp(0, 24);
    _selectedMinute = _nearestMinuteValue(initial % 60);
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _minuteValues.indexOf(_selectedMinute),
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomLift = _bottomLiftFor(
          context,
          metrics,
          constraints.maxHeight,
        );

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              metrics.horizontalPadding,
              0,
              metrics.horizontalPadding,
              bottomLift,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                metrics.isCompact ? 16 : 20,
                metrics.isCompact ? 14 : 18,
                metrics.isCompact ? 16 : 20,
                metrics.isCompact ? 16 : 20,
              ),
              decoration: BoxDecoration(
                color: EventInputStyle.card,
                borderRadius: BorderRadius.circular(metrics.cardRadius),
                border: Border.all(color: EventInputStyle.border),
                boxShadow: EventInputStyle.softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const Spacer(),
                      Text(
                        '$_selectedHour h $_selectedMinute m',
                        style: TextStyle(
                          color: EventInputStyle.textPrimary,
                          fontSize: metrics.cardTitleSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _selectedHour * 60 + _selectedMinute,
                          );
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                  SizedBox(height: metrics.isCompact ? 8 : 12),
                  SizedBox(
                    height: metrics.isCompact ? 168 : 190,
                    child: Row(
                      children: [
                        Expanded(
                          child: _DurationWheel(
                            controller: _hourController,
                            itemCount: _hourCount,
                            suffix: 'h',
                            valueBuilder: (index) => index,
                            onSelectedItemChanged: (index) {
                              setState(() => _selectedHour = index);
                            },
                          ),
                        ),
                        Container(
                          width: 1,
                          height: metrics.isCompact ? 126 : 142,
                          color: EventInputStyle.divider,
                        ),
                        Expanded(
                          child: _DurationWheel(
                            controller: _minuteController,
                            itemCount: _minuteValues.length,
                            suffix: 'm',
                            valueBuilder: (index) => _minuteValues[index],
                            onSelectedItemChanged: (index) {
                              setState(
                                () => _selectedMinute = _minuteValues[index],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _nearestMinuteValue(int minute) {
    final rounded = ((minute / 5).round() * 5).clamp(0, 60);
    return rounded;
  }

  double _bottomLiftFor(
    BuildContext context,
    EventInputMetrics metrics,
    double availableHeight,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final desiredLift = metrics.isCompact
        ? (screenHeight * 0.24).clamp(150.0, 210.0).toDouble()
        : metrics.isExpanded
        ? (screenHeight * 0.30).clamp(260.0, 360.0).toDouble()
        : (screenHeight * 0.28).clamp(190.0, 280.0).toDouble();
    final sheetHeight = metrics.isCompact ? 264.0 : 292.0;
    final maxLift = (availableHeight - sheetHeight - 24).clamp(
      24.0,
      desiredLift,
    );
    return desiredLift.clamp(24.0, maxLift).toDouble();
  }
}

class _DurationWheel extends StatelessWidget {
  const _DurationWheel({
    required this.controller,
    required this.itemCount,
    required this.suffix,
    required this.valueBuilder,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final String suffix;
  final int Function(int index) valueBuilder;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);

    return CupertinoPicker.builder(
      scrollController: controller,
      itemExtent: metrics.isCompact ? 36 : 40,
      magnification: 1.04,
      squeeze: 1.08,
      selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
        background: EventInputStyle.accentSoft.withValues(alpha: 0.72),
      ),
      onSelectedItemChanged: onSelectedItemChanged,
      childCount: itemCount,
      itemBuilder: (context, index) {
        final value = valueBuilder(index);
        return Center(
          child: Text(
            '$value $suffix',
            style: TextStyle(
              color: EventInputStyle.textPrimary,
              fontSize: metrics.isCompact ? 18 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
