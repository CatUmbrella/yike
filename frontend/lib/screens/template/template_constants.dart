import '../../models/template_models.dart';

const templateNameMaxLength = 20;
const templateGoalMaxLength = 100;
const templateStageNameMaxLength = 20;
const templateStageGoalMaxLength = 100;
const templateNoticeMaxLength = 100;

String templateSectionLabel(TemplateSection section) {
  return switch (section) {
    TemplateSection.create => '创建',
    TemplateSection.deploy => '部署',
    TemplateSection.library => '库',
  };
}

String templateCreateTabLabel(TemplateCreateTab tab) {
  return switch (tab) {
    TemplateCreateTab.drafts => '草稿',
    TemplateCreateTab.published => '发布管理',
  };
}

String templateDeployTabLabel(TemplateDeployTab tab) {
  return switch (tab) {
    TemplateDeployTab.notStarted => '未启用',
    TemplateDeployTab.active => '已启用',
    TemplateDeployTab.completed => '已完成',
  };
}

String templateLibraryTabLabel(TemplateLibraryTab tab) {
  return switch (tab) {
    TemplateLibraryTab.official => '官方模板',
  };
}

String templateRelationLabel(TemplateRelation? relation) {
  return switch (relation) {
    TemplateRelation.linear => '线性',
    TemplateRelation.parallel => '并列',
    null => '未选择',
  };
}

String chineseOrderLabel(int order) {
  const labels = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
  if (order >= 1 && order <= labels.length) return labels[order - 1];
  return order.toString();
}

String stageDisplayName(int order) => '阶段${chineseOrderLabel(order)}';
