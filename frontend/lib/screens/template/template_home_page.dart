import 'package:flutter/material.dart';

import '../../models/template_models.dart';
import 'template_constants.dart';
import 'template_create_step1_page.dart';
import 'template_formatters.dart';
import 'template_home_controller.dart';
import 'template_preview_page.dart';
import 'template_style.dart';
import 'widgets/template_list_card.dart';
import 'widgets/template_search_bar.dart';
import 'widgets/template_section_switcher.dart';
import 'widgets/template_side_selector.dart';

class TemplatePage extends StatefulWidget {
  const TemplatePage({super.key});

  @override
  State<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  late final TemplateHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TemplateHomeController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final metrics = TemplateMetrics.forWidth(
          MediaQuery.sizeOf(context).width,
        );
        return Scaffold(
          backgroundColor: TemplateStyle.background,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.horizontalPadding,
                    12,
                    metrics.horizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TemplateSearchBar(
                        value: _controller.searchQuery,
                        onChanged: _controller.updateSearchQuery,
                      ),
                      const SizedBox(height: 6),
                      TemplateSectionSwitcher(
                        selected: _controller.activeSection,
                        onSelected: _controller.switchSection,
                      ),
                      const Divider(height: 1, color: TemplateStyle.border),
                      Expanded(
                        child: _TemplateBody(
                          controller: _controller,
                          metrics: metrics,
                          onCreate: _openCreate,
                          onEdit: _openEdit,
                          onPreview: _openPreview,
                          onDeleteDraft: _confirmDeleteDraft,
                          onDeleteNotStarted: _confirmDeleteNotStarted,
                          onResetActive: _confirmResetActive,
                          onEnable: _enableDeployment,
                          onReuse: _reuseDeployment,
                          onDeployOfficial: _deployOfficial,
                          onPublishUnavailable: _showPublishUnavailable,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_controller.loading)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreate() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TemplateCreateStep1Page()),
    );
    await _controller.load();
  }

  Future<void> _openEdit(TaskTemplate template) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateCreateStep1Page(initialTemplate: template),
      ),
    );
    await _controller.load();
  }

  Future<void> _openPreview(TaskTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplatePreviewPage(template: template),
      ),
    );
  }

  Future<void> _confirmDeleteDraft(TaskTemplate template) async {
    final confirmed = await _confirm(
      title: '删除草稿',
      content: '删除「${template.name}」后将不可恢复，确认删除吗？',
    );
    if (confirmed == true && template.id != null) {
      await _controller.deleteDraft(template.id!);
    }
  }

  Future<void> _confirmDeleteNotStarted(TemplateDeployment deployment) async {
    final confirmed = await _confirm(
      title: '删除模板',
      content: '删除「${deployment.template.name}」后将不可恢复，确认删除吗？',
    );
    if (confirmed == true) {
      await _controller.deleteNotStartedDeployment(deployment.id);
    }
  }

  Future<void> _confirmResetActive(TemplateDeployment deployment) async {
    final confirmed = await _confirm(
      title: '重置部署进度',
      content: '删除会重置所有进度，但模板仍可在未启用中找到。确认继续吗？',
    );
    if (confirmed == true) {
      await _controller.resetActiveDeployment(deployment.id);
    }
  }

  Future<void> _enableDeployment(TemplateDeployment deployment) async {
    if (deployment.template.relation == TemplateRelation.parallel) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('并列模板'),
          content: const Text('该模板支持自选阶段启用。骨架版暂时默认启用当前第一个阶段。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    }
    await _controller.enableDeployment(deployment.id);
  }

  Future<void> _reuseDeployment(TemplateDeployment deployment) async {
    final confirmed = await _confirm(
      title: '复用模板',
      content: '确认将「${deployment.template.name}」再次加入未启用吗？',
    );
    if (confirmed == true) {
      await _controller.reuseCompletedDeployment(deployment.id);
      _showSnack('已进入未启用');
    }
  }

  Future<void> _deployOfficial(TaskTemplate template) async {
    if (template.id == null) return;
    await _controller.deployTemplate(template.id!);
    _showSnack('已加入未启用');
  }

  Future<void> _showPublishUnavailable() async {
    _showSnack('发布管理暂未开放');
  }

  Future<bool?> _confirm({required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _TemplateBody extends StatelessWidget {
  final TemplateHomeController controller;
  final TemplateMetrics metrics;
  final VoidCallback onCreate;
  final ValueChanged<TaskTemplate> onEdit;
  final ValueChanged<TaskTemplate> onPreview;
  final ValueChanged<TaskTemplate> onDeleteDraft;
  final ValueChanged<TemplateDeployment> onDeleteNotStarted;
  final ValueChanged<TemplateDeployment> onResetActive;
  final ValueChanged<TemplateDeployment> onEnable;
  final ValueChanged<TemplateDeployment> onReuse;
  final ValueChanged<TaskTemplate> onDeployOfficial;
  final VoidCallback onPublishUnavailable;

  const _TemplateBody({
    required this.controller,
    required this.metrics,
    required this.onCreate,
    required this.onEdit,
    required this.onPreview,
    required this.onDeleteDraft,
    required this.onDeleteNotStarted,
    required this.onResetActive,
    required this.onEnable,
    required this.onReuse,
    required this.onDeployOfficial,
    required this.onPublishUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: metrics.sideWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: TemplateStyle.sidebar,
            border: Border(
              right: BorderSide(color: TemplateStyle.border),
              left: BorderSide(color: Color(0xFFEDEDEF)),
            ),
          ),
          child: _buildSideSelector(),
        ),
        Expanded(child: _buildMainContent(context)),
      ],
    );
  }

  Widget _buildSideSelector() {
    return switch (controller.activeSection) {
      TemplateSection.create => TemplateSideSelector<TemplateCreateTab>(
        values: TemplateCreateTab.values,
        selected: controller.activeCreateTab,
        labelBuilder: templateCreateTabLabel,
        iconBuilder: (value) => switch (value) {
          TemplateCreateTab.drafts => Icons.description_outlined,
          TemplateCreateTab.published => Icons.near_me_outlined,
        },
        onSelected: controller.switchCreateTab,
      ),
      TemplateSection.deploy => TemplateSideSelector<TemplateDeployTab>(
        values: TemplateDeployTab.values,
        selected: controller.activeDeployTab,
        labelBuilder: templateDeployTabLabel,
        onSelected: controller.switchDeployTab,
      ),
      TemplateSection.library => TemplateSideSelector<TemplateLibraryTab>(
        values: TemplateLibraryTab.values,
        selected: controller.activeLibraryTab,
        labelBuilder: templateLibraryTabLabel,
        onSelected: controller.switchLibraryTab,
      ),
    };
  }

  Widget _buildMainContent(BuildContext context) {
    return switch (controller.activeSection) {
      TemplateSection.create => _buildCreateContent(context),
      TemplateSection.deploy => _buildDeployContent(context),
      TemplateSection.library => _buildLibraryContent(context),
    };
  }

  Widget _buildCreateContent(BuildContext context) {
    if (controller.activeCreateTab == TemplateCreateTab.published) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: _PlaceholderPanel(message: '发布管理暂未开放'),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _MonthGroupedTemplates(
                templates: controller.filteredDrafts,
                emptyMessage: '暂无草稿模板',
                cardBuilder: (template) => TemplateListCard(
                  title: template.name.isEmpty ? '未命名草稿' : template.name,
                  subtitle:
                      '创建时间：${formatTemplateDateTime(template.createdAt)}',
                  onTap: () => onEdit(template),
                  actions: [
                    TemplateTextCardAction(
                      label: '删除',
                      onPressed: () => onDeleteDraft(template),
                    ),
                    TemplateTextCardAction(
                      label: '修改',
                      onPressed: () => onEdit(template),
                    ),
                    TemplateTextCardAction(
                      label: '发布',
                      color: TemplateStyle.accent,
                      onPressed: onPublishUnavailable,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 24),
            label: const Text('创建新模板'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: TemplateStyle.accentSoft,
              foregroundColor: TemplateStyle.accent,
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeployContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: switch (controller.activeDeployTab) {
        TemplateDeployTab.notStarted => _MonthGroupedDeployments(
          deployments: controller.filteredNotStartedDeployments,
          emptyMessage: '暂无未启用模板',
          dateBuilder: (item) => item.deployedAt,
          cardBuilder: (deployment) => TemplateListCard(
            title: deployment.template.name,
            subtitle: '部署时间：${formatTemplateDateTime(deployment.deployedAt)}',
            onTap: () => onPreview(deployment.template),
            actions: [
              TemplateCardAction(
                icon: Icons.delete_outline_rounded,
                tooltip: '删除',
                color: TemplateStyle.warning,
                onPressed: () => onDeleteNotStarted(deployment),
              ),
              TemplateCardAction(
                icon: Icons.visibility_rounded,
                tooltip: '预览',
                onPressed: () => onPreview(deployment.template),
              ),
              TemplateCardAction(
                icon: Icons.play_arrow_rounded,
                tooltip: '启用',
                onPressed: () => onEnable(deployment),
              ),
            ],
          ),
        ),
        TemplateDeployTab.active => _MonthGroupedDeployments(
          deployments: controller.filteredActiveDeployments,
          emptyMessage: '暂无已启用模板',
          dateBuilder: (item) => item.enabledAt ?? item.deployedAt,
          cardBuilder: _buildActiveCard,
        ),
        TemplateDeployTab.completed => _MonthGroupedDeployments(
          deployments: controller.filteredCompletedDeployments,
          emptyMessage: '暂无已完成模板',
          dateBuilder: (item) => item.completedAt ?? item.deployedAt,
          cardBuilder: (deployment) => TemplateListCard(
            title: deployment.template.name,
            subtitle:
                '完成时间：${formatTemplateDateTime(deployment.completedAt ?? deployment.deployedAt)}',
            actions: [
              TemplateCardAction(
                icon: Icons.replay_rounded,
                tooltip: '复用',
                onPressed: () => onReuse(deployment),
              ),
            ],
          ),
        ),
      },
    );
  }

  Widget _buildActiveCard(TemplateDeployment deployment) {
    final stage = deployment.activeStage;
    return TemplateListCard(
      title: deployment.template.name,
      subtitle:
          '启用时间：${formatTemplateDateTime(deployment.enabledAt ?? deployment.deployedAt)}',
      actions: [
        TemplateCardAction(
          icon: Icons.delete_outline_rounded,
          tooltip: '删除',
          color: TemplateStyle.warning,
          onPressed: () => onResetActive(deployment),
        ),
        TemplateCardAction(
          icon: deployment.pauseAfterCurrentStage
              ? Icons.play_circle_outline_rounded
              : Icons.pause_circle_outline_rounded,
          tooltip: '暂停',
          onPressed: () => controller.pauseDeployment(deployment.id),
        ),
        TemplateCardAction(
          icon: deployment.expanded
              ? Icons.unfold_less_rounded
              : Icons.unfold_more_rounded,
          tooltip: deployment.expanded ? '收起' : '展开',
          onPressed: () => controller.toggleDeploymentExpanded(deployment.id),
        ),
      ],
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('用时：${formatTemplateDuration(deployment.elapsedMinutes)}'),
          const SizedBox(height: 6),
          Text(
            '阶段状态：${stage?.name ?? '未开始'} / 共 ${deployment.template.stages.length} 阶段',
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: deployment.progress,
              backgroundColor: TemplateStyle.accentSoft,
            ),
          ),
          if (deployment.expanded) ...[
            const SizedBox(height: 12),
            for (final item in deployment.template.stages)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${stageDisplayName(item.stageOrder)}：${item.name}（${item.eventCount} 个事件）',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemplateStyle.textSecondary,
                  ),
                ),
              ),
            if (deployment.template.notices.isNotEmpty)
              Text(
                '注意：${deployment.template.notices.first.content}',
                style: const TextStyle(
                  fontSize: 12,
                  color: TemplateStyle.textSecondary,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLibraryContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: _MonthGroupedTemplates(
        templates: controller.filteredOfficialTemplates,
        emptyMessage: '暂无官方模板',
        cardBuilder: (template) => TemplateListCard(
          title: template.name,
          subtitle: template.goal,
          onTap: () => onPreview(template),
          actions: [
            TemplateCardAction(
              icon: Icons.visibility_rounded,
              tooltip: '预览',
              onPressed: () => onPreview(template),
            ),
            TemplateCardAction(
              icon: Icons.add_task_rounded,
              tooltip: '部署',
              onPressed: () => onDeployOfficial(template),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGroupedTemplates extends StatelessWidget {
  final List<TaskTemplate> templates;
  final String emptyMessage;
  final Widget Function(TaskTemplate template) cardBuilder;

  const _MonthGroupedTemplates({
    required this.templates,
    required this.emptyMessage,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) return _PlaceholderPanel(message: emptyMessage);

    String? lastMonth;
    final children = <Widget>[];
    for (final template in templates) {
      final month = formatTemplateMonth(template.createdAt);
      if (month != lastMonth) {
        children.add(_MonthHeader(label: month));
        lastMonth = month;
      }
      children.add(cardBuilder(template));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _MonthGroupedDeployments extends StatelessWidget {
  final List<TemplateDeployment> deployments;
  final String emptyMessage;
  final DateTime Function(TemplateDeployment item) dateBuilder;
  final Widget Function(TemplateDeployment deployment) cardBuilder;

  const _MonthGroupedDeployments({
    required this.deployments,
    required this.emptyMessage,
    required this.dateBuilder,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (deployments.isEmpty) return _PlaceholderPanel(message: emptyMessage);

    String? lastMonth;
    final children = <Widget>[];
    for (final deployment in deployments) {
      final month = formatTemplateMonth(dateBuilder(deployment));
      if (month != lastMonth) {
        children.add(_MonthHeader(label: month));
        lastMonth = month;
      }
      children.add(cardBuilder(deployment));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;

  const _MonthHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: TemplateStyle.accent,
        ),
      ),
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  final String message;

  const _PlaceholderPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: TemplateStyle.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TemplateStyle.border),
        boxShadow: TemplateStyle.itemShadow,
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: TemplateStyle.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
