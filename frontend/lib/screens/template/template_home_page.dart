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
  final bool active;

  const TemplatePage({super.key, this.active = true});

  @override
  State<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  late final TemplateHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TemplateHomeController();
    if (widget.active) {
      _controller.load();
    }
  }

  @override
  void didUpdateWidget(covariant TemplatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _controller.load();
    }
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
      content: '重置后，本次部署生成的事件将移入回收站，部署进度清空，模板会回到未启用。确认继续吗？',
    );
    if (confirmed == true) {
      await _controller.resetActiveDeployment(deployment.id);
    }
  }

  Future<void> _enableDeployment(TemplateDeployment deployment) async {
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
                selectedMonth: controller.selectedMonth,
                onMonthSelected: controller.selectMonth,
                cardBuilder: (template) => TemplateListCard(
                  title: template.name.isEmpty ? '未命名草稿' : template.name,
                  subtitle:
                      '创建时间：${formatTemplateDateTime(template.createdAt)}',
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
              backgroundColor: const Color(0xFFE2F0FF),
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
          selectedMonth: controller.selectedMonth,
          onMonthSelected: controller.selectMonth,
          cardBuilder: (deployment) => TemplateListCard(
            title: deployment.template.name,
            subtitle: '部署时间：${formatTemplateDateTime(deployment.deployedAt)}',
            actions: [
              TemplateTextCardAction(
                label: '删除',
                onPressed: () => onDeleteNotStarted(deployment),
              ),
              TemplateTextCardAction(
                label: '预览',
                onPressed: () => onPreview(deployment.template),
              ),
              TemplateTextCardAction(
                label: '启用',
                color: TemplateStyle.accent,
                onPressed: () => onEnable(deployment),
              ),
            ],
          ),
        ),
        TemplateDeployTab.active => _MonthGroupedDeployments(
          deployments: controller.filteredActiveDeployments,
          emptyMessage: '暂无已启用模板',
          selectedMonth: controller.selectedMonth,
          onMonthSelected: controller.selectMonth,
          cardBuilder: _buildActiveCard,
        ),
        TemplateDeployTab.completed => _MonthGroupedDeployments(
          deployments: controller.filteredCompletedDeployments,
          emptyMessage: '暂无已完成模板',
          selectedMonth: controller.selectedMonth,
          onMonthSelected: controller.selectMonth,
          cardBuilder: (deployment) => TemplateListCard(
            title: deployment.template.name,
            subtitle:
                '完成时间：${formatTemplateDateTime(deployment.completedAt ?? deployment.deployedAt)}',
            actions: [
              TemplateTextCardAction(
                label: '复用',
                color: TemplateStyle.accent,
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
        TemplateTextCardAction(
          label: '删除',
          onPressed: () => onResetActive(deployment),
        ),
        TemplateTextCardAction(
          label: deployment.pauseAfterCurrentStage ? '继续' : '暂停',
          onPressed: () => controller.pauseDeployment(deployment.id),
        ),
        TemplateTextCardAction(
          label: deployment.expanded ? '收起' : '展开',
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
              _buildDeploymentStageDetail(deployment, item),
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

  Widget _buildDeploymentStageDetail(
    TemplateDeployment deployment,
    TemplateStage stage,
  ) {
    final progress = deployment.progressForStage(stage);
    final canEnable =
        deployment.template.relation == TemplateRelation.parallel &&
        stage.id != null &&
        progress?.status != TemplateDeploymentStageStatus.completed &&
        progress?.status != TemplateDeploymentStageStatus.inProgress;
    final buttonLabel = switch (progress?.status) {
      TemplateDeploymentStageStatus.completed => '已完成',
      TemplateDeploymentStageStatus.inProgress => '正在进行',
      _ => '启用',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: TemplateStyle.accentSofter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TemplateStyle.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${stageDisplayName(stage.stageOrder)}：${stage.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TemplateStyle.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: canEnable
                    ? () => controller.enableDeploymentStage(
                        deployment.id,
                        stage.id!,
                      )
                    : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(56, 32),
                  foregroundColor: TemplateStyle.accent,
                  disabledForegroundColor: TemplateStyle.textSecondary,
                ),
                child: Text(buttonLabel),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '进度：${progress?.completedEventCount ?? 0}/${progress?.totalEventCount ?? stage.eventCount}',
            style: const TextStyle(
              fontSize: 12,
              color: TemplateStyle.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          if (stage.events.isEmpty)
            const Text(
              '暂无事件',
              style: TextStyle(
                fontSize: 12,
                color: TemplateStyle.textSecondary,
              ),
            )
          else
            for (final event in stage.events)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 7, right: 7),
                      decoration: const BoxDecoration(
                        color: TemplateStyle.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: TemplateStyle.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildLibraryContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: _TemplateList(
        templates: controller.filteredOfficialTemplates,
        emptyMessage: '暂无官方模板',
        cardBuilder: (template) => TemplateListCard(
          title: template.name,
          subtitle: template.goal,
          actions: [
            TemplateTextCardAction(
              label: '预览',
              onPressed: () => onPreview(template),
            ),
            TemplateTextCardAction(
              label: '部署',
              color: TemplateStyle.accent,
              onPressed: () => onDeployOfficial(template),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateList extends StatelessWidget {
  final List<TaskTemplate> templates;
  final String emptyMessage;
  final Widget Function(TaskTemplate template) cardBuilder;

  const _TemplateList({
    required this.templates,
    required this.emptyMessage,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) return _PlaceholderPanel(message: emptyMessage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final template in templates) cardBuilder(template)],
    );
  }
}

class _MonthGroupedTemplates extends StatelessWidget {
  final List<TaskTemplate> templates;
  final String emptyMessage;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;
  final Widget Function(TaskTemplate template) cardBuilder;

  const _MonthGroupedTemplates({
    required this.templates,
    required this.emptyMessage,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthHeader(
          selectedMonth: selectedMonth,
          onMonthSelected: onMonthSelected,
        ),
        if (templates.isEmpty)
          _PlaceholderPanel(message: emptyMessage)
        else
          for (final template in templates) cardBuilder(template),
      ],
    );
  }
}

class _MonthGroupedDeployments extends StatelessWidget {
  final List<TemplateDeployment> deployments;
  final String emptyMessage;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;
  final Widget Function(TemplateDeployment deployment) cardBuilder;

  const _MonthGroupedDeployments({
    required this.deployments,
    required this.emptyMessage,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthHeader(
          selectedMonth: selectedMonth,
          onMonthSelected: onMonthSelected,
        ),
        if (deployments.isEmpty)
          _PlaceholderPanel(message: emptyMessage)
        else
          for (final deployment in deployments) cardBuilder(deployment),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const _MonthHeader({
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _pickMonth(context),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
          label: Text(formatTemplateMonth(selectedMonth)),
          style: TextButton.styleFrom(
            foregroundColor: TemplateStyle.accent,
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MonthPickerSheet(initialMonth: selectedMonth),
    );
    if (picked != null) {
      onMonthSelected(picked);
    }
  }
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime initialMonth;

  const _MonthPickerSheet({required this.initialMonth});

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: TemplateStyle.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: TemplateStyle.border),
          boxShadow: TemplateStyle.panelShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '$_year年',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TemplateStyle.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;
                final selected =
                    _year == widget.initialMonth.year &&
                    month == widget.initialMonth.month;
                return FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, DateTime(_year, month)),
                  style: FilledButton.styleFrom(
                    backgroundColor: selected
                        ? TemplateStyle.accent
                        : TemplateStyle.accentSoft,
                    foregroundColor: selected
                        ? Colors.white
                        : TemplateStyle.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('$month月'),
                );
              },
            ),
          ],
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
