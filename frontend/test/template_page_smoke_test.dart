import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/template_models.dart';
import 'package:frontend/screens/template_page.dart';
import 'package:frontend/screens/template/template_create_controller.dart';
import 'package:frontend/screens/template/template_create_exit.dart';
import 'package:frontend/screens/template/template_create_step2_page.dart';
import 'package:frontend/screens/template/template_create_step3_page.dart';
import 'package:frontend/screens/template/template_create_step4_page.dart';
import 'package:frontend/screens/template/template_home_controller.dart';

void main() {
  test('template stage editing starts from first stage', () {
    final controller = TemplateCreateController.newDraft();
    addTearDown(controller.dispose);

    controller.updateStageName(0, 'stage one');
    controller.updateStageGoal(0, 'stage one goal');
    controller.addStage();
    controller.updateStageName(1, 'stage two');
    controller.updateStageGoal(1, 'stage two goal');
    controller.currentStageIndex = 1;

    controller.startStageEditing();

    expect(controller.currentStep, 2);
    expect(controller.currentStageIndex, 0);
    expect(controller.currentStage.name, 'stage one');
    expect(controller.currentStage.events, isNotEmpty);
  });

  test('template step two requires every event title', () {
    final controller = TemplateCreateController.newDraft();
    addTearDown(controller.dispose);

    controller.updateStageName(0, 'stage');
    controller.updateStageGoal(0, 'goal');
    controller.addEventToCurrentStage();

    expect(controller.canContinueStep2, isFalse);

    controller.updateCurrentStageEventTitle(0, 'event one');
    expect(controller.canContinueStep2, isTrue);

    controller.addEventToCurrentStage();
    expect(controller.canContinueStep2, isFalse);

    controller.updateCurrentStageEventTitle(1, 'event two');
    expect(controller.canContinueStep2, isTrue);
  });

  test('template home filters templates by selected month', () {
    final controller = TemplateHomeController();
    addTearDown(controller.dispose);
    controller.selectedMonth = DateTime(2026, 6);
    controller.drafts = [
      _templateFixture(),
      _templateFixture().copyWith(
        id: 2,
        name: '五月模板',
        createdAt: DateTime(2026, 5, 20),
        updatedAt: DateTime(2026, 5, 20),
      ),
    ];

    expect(controller.filteredDrafts.map((item) => item.name), ['模板']);

    controller.selectMonth(DateTime(2026, 5));

    expect(controller.filteredDrafts.map((item) => item.name), ['五月模板']);
  });

  test('template official library ignores selected month', () {
    final controller = TemplateHomeController();
    addTearDown(controller.dispose);
    controller.selectedMonth = DateTime(2026, 6);
    controller.officialTemplates = [
      _templateFixture().copyWith(name: '六月官方'),
      _templateFixture().copyWith(
        id: 2,
        name: '五月官方',
        createdAt: DateTime(2026, 5, 20),
        updatedAt: DateTime(2026, 5, 20),
      ),
    ];

    expect(controller.filteredOfficialTemplates.map((item) => item.name), [
      '六月官方',
      '五月官方',
    ]);
  });

  testWidgets('template exit skips save dialog without changes', (
    tester,
  ) async {
    final controller = TemplateCreateController.fromTemplate(
      _templateFixture(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => handleTemplateCreateExit(context, controller),
              child: const Text('exit'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('exit'));
    await tester.pumpAndSettle();

    expect(find.text('保存草稿'), findsNothing);
  });

  testWidgets('template page opens create flow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TemplatePage()));
    await tester.pumpAndSettle();

    expect(find.text('搜索模板'), findsOneWidget);
    expect(find.text('创建'), findsOneWidget);
    expect(find.text('创建新模板'), findsOneWidget);

    await tester.tap(find.text('创建新模板'));
    await tester.pumpAndSettle();

    expect(find.text('模板名称：'), findsOneWidget);
    expect(find.text('总目标：'), findsOneWidget);
    expect(find.text('阶段一：'), findsOneWidget);

    Future<void> addStage() async {
      await tester.ensureVisible(find.byTooltip('新增阶段'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('新增阶段'));
      await tester.pumpAndSettle();
    }

    await addStage();
    await tester.pump();
    expect(find.text('阶段二：'), findsOneWidget);

    await addStage();
    expect(find.text('阶段三：'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.ensureVisible(fields.at(4));
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(4), '阶段二名称');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(fields.at(6));
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(6), '阶段三名称');
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('删除阶段二'));
    await tester.pumpAndSettle();
    expect(find.text('删除阶段'), findsOneWidget);
    expect(find.text('确认删除阶段二吗？该阶段下的内容会被直接删除，无法恢复。'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();
    expect(find.text('阶段二名称'), findsNothing);
    expect(find.text('阶段三名称'), findsOneWidget);
    expect(find.text('阶段三：'), findsNothing);

    final createScaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(createScaffold.resizeToAvoidBottomInset, isFalse);

    final firstEditableText = find.byType(EditableText).first;
    bool firstInputHasFocus() {
      return tester.widget<EditableText>(firstEditableText).focusNode.hasFocus;
    }

    await tester.tap(firstEditableText);
    await tester.enterText(find.byType(TextFormField).first, 'AAA');
    await tester.pump(const Duration(milliseconds: 500));
    expect(firstInputHasFocus(), isTrue);

    await tester.tapAt(const Offset(10, 300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(firstInputHasFocus(), isFalse);
  });

  testWidgets('template create step two renders editable content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TemplateCreateController.newDraft();
    addTearDown(controller.dispose);
    controller.updateStageName(0, '阶段A');
    controller.updateStageGoal(0, '阶段目标A');
    controller.addEventToCurrentStage();
    controller.moveToStep(2);

    await tester.pumpWidget(
      MaterialApp(home: TemplateCreateStep2Page(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('阶段一：'), findsOneWidget);
    expect(find.text('目标：'), findsOneWidget);
    expect(find.text('预计耗时：'), findsWidgets);
    expect(find.text('目的:'), findsOneWidget);
    expect(find.text('怎么做:'), findsOneWidget);
    expect(find.text('第一步:'), findsOneWidget);
    expect(find.byTooltip('添加子任务'), findsOneWidget);
    expect(find.text('上一步'), findsOneWidget);
    expect(find.text('进入总览'), findsOneWidget);
  });

  testWidgets('template create step three renders aligned overview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TemplateCreateController.newDraft();
    addTearDown(controller.dispose);
    controller.updateStageName(0, '建立框架');
    controller.updateStageGoal(0, '明确阶段目的');
    controller.addEventToCurrentStage();
    controller.updateCurrentStageEventTitle(0, '建立演示核心框架');
    controller.updateCurrentStageEventPurpose(0, '锚定演示方向');
    controller.updateCurrentStageEventStepDescription(0, 0, '拆解演示的核心诉求');
    controller.updateCurrentStageEventStepMinutes(0, 0, 30);
    controller.moveToStep(3);

    await tester.pumpWidget(
      MaterialApp(home: TemplateCreateStep3Page(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('总览'), findsOneWidget);
    expect(find.text('共1件事'), findsOneWidget);
    expect(find.text('阶段一：'), findsOneWidget);
    expect(find.text('建立框架'), findsOneWidget);
    expect(find.text('一：'), findsOneWidget);
    expect(find.text('建立演示核心框架'), findsOneWidget);
    expect(find.text('第一步：'), findsOneWidget);
    expect(find.text('拆解演示的核心诉求'), findsOneWidget);
    expect(find.text('30m'), findsNWidgets(2));
    expect(find.text('上一步'), findsOneWidget);
    expect(find.text('下一阶段'), findsOneWidget);
  });

  testWidgets('template create step four renders previous action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TemplateCreateController.newDraft();
    addTearDown(controller.dispose);
    controller.moveToStep(4);

    await tester.pumpWidget(
      MaterialApp(home: TemplateCreateStep4Page(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('部署准备'), findsOneWidget);
    expect(find.text('上一步'), findsOneWidget);
    expect(find.text('导出到草稿箱'), findsOneWidget);
  });
}

TaskTemplate _templateFixture() {
  final now = DateTime(2026, 6, 12);
  return TaskTemplate(
    id: 1,
    name: '模板',
    goal: '目标',
    source: TemplateSource.user,
    status: TemplateStatus.draft,
    relation: null,
    currentCreateStep: 1,
    currentStageIndex: 0,
    createCompleted: false,
    stages: const [
      TemplateStage(
        id: 1,
        stageOrder: 1,
        name: '阶段',
        goal: '阶段目标',
        estimatedMinutes: 0,
        events: [
          TemplateStageEvent(
            id: 1,
            eventOrder: 1,
            title: '事件',
            purpose: '目的',
            estimatedMinutes: 10,
            steps: [
              TemplateStageEventStep(
                id: 1,
                stepOrder: 1,
                description: '步骤',
                estimatedMinutes: 10,
              ),
            ],
          ),
        ],
      ),
    ],
    notices: const [],
    createdAt: now,
    updatedAt: now,
  );
}
