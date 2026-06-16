import 'package:flutter/material.dart';

import 'template_create_controller.dart';
import 'widgets/template_keyboard_dismiss.dart';

Future<void> handleTemplateCreateExit(
  BuildContext context,
  TemplateCreateController controller,
) async {
  if (!controller.dirty) {
    _popToHome(context);
    return;
  }

  final decision = await showDialog<_ExitDecision>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('保存草稿'),
      content: const Text('当前内容已有编辑，是否保存为草稿？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _ExitDecision.cancel),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _ExitDecision.discard),
          child: const Text('不保存'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _ExitDecision.save),
          child: const Text('保存'),
        ),
      ],
    ),
  );

  if (!context.mounted ||
      decision == null ||
      decision == _ExitDecision.cancel) {
    return;
  }

  if (decision == _ExitDecision.discard) {
    _popToHome(context);
    return;
  }

  if (controller.templateName.trim().isEmpty) {
    final name = await _requestTemplateName(context);
    if (!context.mounted || name == null || name.trim().isEmpty) return;
    controller.updateTemplateName(name.trim());
  }

  await controller.saveDraft();
  if (context.mounted) _popToHome(context);
}

Future<String?> _requestTemplateName(BuildContext context) {
  final input = TextEditingController(text: '草稿模板1');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('编辑模板名称'),
      content: TextField(
        controller: input,
        autofocus: true,
        maxLength: 20,
        onTapOutside: (_) => dismissTemplateKeyboard(),
        onTap: () => ensureTemplateInputVisible(ctx),
        scrollPadding: templateInputScrollPadding(ctx),
        decoration: const InputDecoration(hintText: '模板名称'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, input.text),
          child: const Text('确认'),
        ),
      ],
    ),
  );
}

void _popToHome(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

enum _ExitDecision { save, discard, cancel }
