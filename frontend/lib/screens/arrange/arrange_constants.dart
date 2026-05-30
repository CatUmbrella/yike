class ArrangeTimeSlot {
  final String start;
  final String end;
  final int rowFlex;

  const ArrangeTimeSlot(this.start, this.end, this.rowFlex);

  String get key => '$start-$end';
}

const initialEventPage = 15000;
const initialCalendarPage = 15000;
const arrangePageCount = 30000;

const arrangeTabs = ['事件箱', '已完成', '回收站'];
const arrangeWeekLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

const arrangeTimeSlots = [
  ArrangeTimeSlot('0:00', '8:00', 5),
  ArrangeTimeSlot('8:00', '10:00', 7),
  ArrangeTimeSlot('10:00', '12:00', 9),
  ArrangeTimeSlot('12:00', '16:00', 9),
  ArrangeTimeSlot('16:00', '20:00', 7),
  ArrangeTimeSlot('20:00', '24:00', 5),
];

const calendarTimeAxisWidth = 32.0;
const calendarEventItemExtent = 13.0;
const calendarEventChipHeight = 12.0;
const calendarEventChipWidth = 68.0;
const eventBoxFeedbackStartWidth = 210.0;
const eventBoxFeedbackEndWidth = 76.0;
const eventBoxFeedbackEndHeight = 12.0;
