import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/template_models.dart';
import 'package:frontend/repositories/template_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('template repository persists draft lifecycle', () async {
    final repository = TemplateRepository();
    final uniqueName = '测试草稿${DateTime.now().microsecondsSinceEpoch}';
    int? draftId;

    try {
      final saved = await repository.saveDraft(
        TaskTemplate(
          name: uniqueName,
          goal: '验证草稿保存和回读',
          source: TemplateSource.user,
          status: TemplateStatus.draft,
          relation: TemplateRelation.linear,
          currentCreateStep: 4,
          currentStageIndex: 0,
          createCompleted: true,
          stages: const [
            TemplateStage(
              stageOrder: 1,
              name: '阶段一',
              goal: '完成第一阶段',
              estimatedMinutes: 30,
              events: [
                TemplateStageEvent(
                  eventOrder: 1,
                  title: '事件一',
                  purpose: '验证事件保存',
                  estimatedMinutes: 30,
                  steps: [
                    TemplateStageEventStep(
                      stepOrder: 1,
                      description: '步骤一',
                      estimatedMinutes: 30,
                    ),
                  ],
                ),
              ],
            ),
          ],
          notices: const [TemplateNotice(noticeOrder: 1, content: '注意事项')],
          createdAt: DateTime(2026, 6, 12),
          updatedAt: DateTime(2026, 6, 12),
        ),
      );
      draftId = saved.id;

      expect(draftId, isNotNull);
      expect(saved.stages.single.events.single.steps.single.description, '步骤一');

      final loaded = await repository.loadTemplate(draftId!);
      expect(loaded?.name, uniqueName);
      expect(loaded?.stages.single.events.single.title, '事件一');
      expect(loaded?.notices.single.content, '注意事项');

      final updated = await repository.saveDraft(
        loaded!.copyWith(goal: '修改后的目标'),
      );
      expect(updated.goal, '修改后的目标');

      final snapshot = await repository.loadHome();
      expect(
        snapshot.drafts.any(
          (template) => template.id == draftId && template.goal == '修改后的目标',
        ),
        isTrue,
      );
    } finally {
      if (draftId != null) {
        await repository.deleteDraft(draftId);
      }
    }

    final savedDraftId = draftId;
    final afterDelete = await repository.loadTemplate(savedDraftId);
    expect(afterDelete, isNull);
  });
}
