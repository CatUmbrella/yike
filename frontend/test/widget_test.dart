import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App shows bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const YiKeApp());
    expect(find.text('事件箱'), findsOneWidget);
    expect(find.text('日历'), findsOneWidget);
    expect(find.text('四象限'), findsOneWidget);
    expect(find.text('番茄钟'), findsOneWidget);
  });
}
