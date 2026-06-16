import 'package:flutter/material.dart';

import '../../models/template_models.dart';
import 'template_constants.dart';
import 'template_create_controller.dart';
import 'template_create_exit.dart';
import 'template_style.dart';
import 'widgets/template_create_top_bar.dart';
import 'widgets/template_form_panel.dart';
import 'widgets/template_keyboard_dismiss.dart';
import 'widgets/template_primary_button.dart';

class TemplateCreateStep4Page extends StatelessWidget {
  final TemplateCreateController controller;

  const TemplateCreateStep4Page({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: TemplateStyle.background,
          body: TemplateKeyboardDismiss(
            child: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  28 + MediaQuery.viewInsetsOf(context).bottom * 0.42,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TemplateCreateTopBar(
                      title: '部署准备',
                      onBackToTemplates: () =>
                          handleTemplateCreateExit(context, controller),
                      onPrevious: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 14),
                    TemplateFormPanel(
                      title: '选择关系',
                      child: Row(
                        children: [
                          Expanded(
                            child: _RelationButton(
                              label: '线性',
                              selected:
                                  controller.relation ==
                                  TemplateRelation.linear,
                              onTap: () => controller.updateRelation(
                                TemplateRelation.linear,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RelationButton(
                              label: '并列',
                              selected:
                                  controller.relation ==
                                  TemplateRelation.parallel,
                              onTap: () => controller.updateRelation(
                                TemplateRelation.parallel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TemplateFormPanel(
                      title: '注意事项',
                      child: Column(
                        children: [
                          for (var i = 0; i < controller.notices.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                key: ValueKey('notice-$i'),
                                initialValue: controller.notices[i].content,
                                maxLength: templateNoticeMaxLength,
                                maxLines: 2,
                                onTapOutside: (_) => dismissTemplateKeyboard(),
                                onTap: () =>
                                    ensureTemplateInputVisible(context),
                                scrollPadding: templateInputScrollPadding(
                                  context,
                                ),
                                onChanged: (value) =>
                                    controller.updateNotice(i, value),
                                decoration: InputDecoration(
                                  labelText: '注意事项${chineseOrderLabel(i + 1)}',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton.filledTonal(
                              tooltip: '新增注意事项',
                              onPressed: controller.addNotice,
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TemplatePrimaryButton(
                      label: '导出到草稿箱',
                      onPressed: controller.canExport
                          ? () => _exportDraft(context)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportDraft(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存模板'),
        content: const Text('确认导出到草稿箱吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.saveDraft(completed: true);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _RelationButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RelationButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? TemplateStyle.accent : TemplateStyle.accentSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : TemplateStyle.accent,
          ),
        ),
      ),
    );
  }
}
