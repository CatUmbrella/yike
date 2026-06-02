import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App shows bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const YiKeApp());

    expect(find.text('安排'), findsOneWidget);
    expect(find.text('番茄钟'), findsOneWidget);
    expect(find.text('模板'), findsOneWidget);
    expect(find.text('数据'), findsOneWidget);
  });
}
