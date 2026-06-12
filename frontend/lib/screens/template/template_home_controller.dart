import 'package:flutter/foundation.dart';

import '../../models/template_models.dart';
import '../../repositories/template_repository.dart';

class TemplateHomeController extends ChangeNotifier {
  TemplateHomeController({TemplateRepository? repository})
    : _repository = repository ?? TemplateRepository();

  final TemplateRepository _repository;

  bool loading = true;
  Object? error;
  TemplateSection activeSection = TemplateSection.create;
  TemplateCreateTab activeCreateTab = TemplateCreateTab.drafts;
  TemplateDeployTab activeDeployTab = TemplateDeployTab.notStarted;
  TemplateLibraryTab activeLibraryTab = TemplateLibraryTab.official;
  String searchQuery = '';

  List<TaskTemplate> drafts = const [];
  List<TemplateDeployment> notStartedDeployments = const [];
  List<TemplateDeployment> activeDeployments = const [];
  List<TemplateDeployment> completedDeployments = const [];
  List<TaskTemplate> officialTemplates = const [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final snapshot = await _repository.loadHome();
      drafts = snapshot.drafts;
      notStartedDeployments = snapshot.notStartedDeployments;
      activeDeployments = snapshot.activeDeployments;
      completedDeployments = snapshot.completedDeployments;
      officialTemplates = snapshot.officialTemplates;
    } catch (err) {
      error = err;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void switchSection(TemplateSection section) {
    if (activeSection == section) return;
    activeSection = section;
    notifyListeners();
  }

  void switchCreateTab(TemplateCreateTab tab) {
    if (activeCreateTab == tab) return;
    activeCreateTab = tab;
    notifyListeners();
  }

  void switchDeployTab(TemplateDeployTab tab) {
    if (activeDeployTab == tab) return;
    activeDeployTab = tab;
    notifyListeners();
  }

  void switchLibraryTab(TemplateLibraryTab tab) {
    if (activeLibraryTab == tab) return;
    activeLibraryTab = tab;
    notifyListeners();
  }

  void updateSearchQuery(String value) {
    if (searchQuery == value) return;
    searchQuery = value;
    notifyListeners();
  }

  List<TaskTemplate> get filteredDrafts {
    return _filterTemplates(drafts);
  }

  List<TaskTemplate> get filteredOfficialTemplates {
    return _filterTemplates(officialTemplates);
  }

  List<TemplateDeployment> get filteredNotStartedDeployments {
    return _filterDeployments(notStartedDeployments);
  }

  List<TemplateDeployment> get filteredActiveDeployments {
    return _filterDeployments(activeDeployments);
  }

  List<TemplateDeployment> get filteredCompletedDeployments {
    return _filterDeployments(completedDeployments);
  }

  Future<void> deleteDraft(int templateId) async {
    await _repository.deleteDraft(templateId);
    await load();
  }

  Future<void> deleteNotStartedDeployment(int deploymentId) async {
    await _repository.deleteNotStartedDeployment(deploymentId);
    await load();
  }

  Future<void> enableDeployment(int deploymentId) async {
    await _repository.enableDeployment(deploymentId);
    activeSection = TemplateSection.deploy;
    activeDeployTab = TemplateDeployTab.active;
    await load();
  }

  Future<void> resetActiveDeployment(int deploymentId) async {
    await _repository.resetActiveDeployment(deploymentId);
    activeSection = TemplateSection.deploy;
    activeDeployTab = TemplateDeployTab.notStarted;
    await load();
  }

  Future<void> pauseDeployment(int deploymentId) async {
    await _repository.pauseDeployment(deploymentId);
    await load();
  }

  Future<void> toggleDeploymentExpanded(int deploymentId) async {
    await _repository.toggleDeploymentExpanded(deploymentId);
    await load();
  }

  Future<void> reuseCompletedDeployment(int deploymentId) async {
    await _repository.reuseCompletedDeployment(deploymentId);
    activeSection = TemplateSection.deploy;
    activeDeployTab = TemplateDeployTab.notStarted;
    await load();
  }

  Future<void> deployTemplate(int templateId) async {
    await _repository.deployTemplate(templateId);
    activeSection = TemplateSection.deploy;
    activeDeployTab = TemplateDeployTab.notStarted;
    await load();
  }

  List<TaskTemplate> _filterTemplates(List<TaskTemplate> templates) {
    final query = searchQuery.trim();
    if (query.isEmpty) return templates;
    return templates
        .where(
          (template) =>
              template.name.contains(query) || template.goal.contains(query),
        )
        .toList();
  }

  List<TemplateDeployment> _filterDeployments(
    List<TemplateDeployment> deployments,
  ) {
    final query = searchQuery.trim();
    if (query.isEmpty) return deployments;
    return deployments
        .where(
          (deployment) =>
              deployment.template.name.contains(query) ||
              deployment.template.goal.contains(query),
        )
        .toList();
  }
}
