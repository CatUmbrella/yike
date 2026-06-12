import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/template_page.dart';

void main() {
  testWidgets('template page opens create flow', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplatePage()));
    await tester.pumpAndSettle();

    expect(find.text('搜索模板'), findsOneWidget);
    expect(find.text('创建'), findsOneWidget);
    expect(find.text('创建新模板'), findsOneWidget);

    await tester.tap(find.text('创建新模板'));
    await tester.pumpAndSettle();

    expect(find.text('创建模板'), findsOneWidget);
    expect(find.text('模板总题目'), findsOneWidget);
  });
}
