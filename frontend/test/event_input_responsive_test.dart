import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/event_input.dart';

void main() {
  testWidgets('event input page renders across compact regular expanded widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in <Size>[
      const Size(360, 780),
      const Size(600, 900),
      const Size(900, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(home: EventInputScreen(key: ValueKey(size.width))),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('自定义事件'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('事件名称'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      expect(find.text('保存'), findsNothing);

      final textFields = find.byType(EditableText);
      expect(textFields, findsNWidgets(4));

      await tester.enterText(
        textFields.at(2),
        'purpose wraps to multiple lines while keeping adaptive underlines',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        textFields.at(3),
        'step description wraps through several visual lines while duration moves line by line',
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final deleteButton = find.widgetWithText(FilledButton, '删除');
      await tester.ensureVisible(deleteButton);
      tester.widget<FilledButton>(deleteButton).onPressed?.call();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('事件名称'), findsNothing);
    }
  });
}
