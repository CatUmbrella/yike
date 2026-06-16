import '../models/template_models.dart';
import '../services/api.dart';
import '../services/database.dart';

class TemplateRepository {
  TemplateRepository();

  static List<TaskTemplate> _officialCache = const [];
  static final Set<int> _expandedDeploymentIds = <int>{};

  Future<TemplateHomeSnapshot> loadHome() async {
    final drafts = await LocalDatabase.getDraftTemplates();
    final officialTemplates = await _loadOfficialTemplates();
    final deployments = [
      for (final deployment in await LocalDatabase.getTemplateDeployments())
        deployment.copyWith(
          expanded: _expandedDeploymentIds.contains(deployment.id),
        ),
    ];
    return TemplateHomeSnapshot(
      drafts: List.unmodifiable(drafts),
      notStartedDeployments: List.unmodifiable(
        deployments.where(
          (item) => item.status == TemplateDeploymentStatus.notStarted,
        ),
      ),
      activeDeployments: List.unmodifiable(
        deployments.where(
          (item) => item.status == TemplateDeploymentStatus.active,
        ),
      ),
      completedDeployments: List.unmodifiable(
        deployments.where(
          (item) => item.status == TemplateDeploymentStatus.completed,
        ),
      ),
      officialTemplates: List.unmodifiable(officialTemplates),
    );
  }

  Future<TaskTemplate?> loadTemplate(int templateId) async {
    final stored = await LocalDatabase.getTemplateById(templateId);
    if (stored != null) return stored;

    for (final template in _officialCache) {
      if (template.id == templateId) return template;
    }
    return null;
  }

  Future<List<TaskTemplate>> _loadOfficialTemplates() async {
    final remote = await ApiService.fetchOfficialTemplates();
    if (remote != null) {
      _officialCache = remote;
      return remote;
    }
    return _officialCache;
  }

  Future<TaskTemplate> saveDraft(TaskTemplate draft) async {
    return LocalDatabase.saveDraftTemplate(
      draft.copyWith(source: TemplateSource.user, status: TemplateStatus.draft),
    );
  }

  Future<void> deleteDraft(int templateId) async {
    await LocalDatabase.deleteDraftTemplate(templateId);
  }

  Future<void> deleteNotStartedDeployment(int deploymentId) async {
    _expandedDeploymentIds.remove(deploymentId);
    await LocalDatabase.deleteTemplateDeployment(deploymentId);
  }

  Future<void> enableDeployment(int deploymentId) async {
    await LocalDatabase.enableTemplateDeployment(deploymentId);
  }

  Future<void> enableDeploymentStage(int deploymentId, int stageId) async {
    await LocalDatabase.enableTemplateDeploymentStage(deploymentId, stageId);
  }

  Future<void> resetActiveDeployment(int deploymentId) async {
    _expandedDeploymentIds.remove(deploymentId);
    await LocalDatabase.resetTemplateDeployment(deploymentId);
  }

  Future<void> pauseDeployment(int deploymentId) async {
    await LocalDatabase.pauseTemplateDeployment(deploymentId);
  }

  Future<void> toggleDeploymentExpanded(int deploymentId) async {
    if (!_expandedDeploymentIds.add(deploymentId)) {
      _expandedDeploymentIds.remove(deploymentId);
    }
  }

  Future<void> reuseCompletedDeployment(int deploymentId) async {
    final deployments = await LocalDatabase.getTemplateDeployments();
    final matches = deployments.where((item) => item.id == deploymentId);
    if (matches.isEmpty) return;
    await LocalDatabase.createTemplateDeployment(matches.first.template);
  }

  Future<void> deployTemplate(int templateId) async {
    final source = await loadTemplate(templateId);
    if (source == null) return;
    final stored = await LocalDatabase.ensureStoredTemplate(source);
    await LocalDatabase.createTemplateDeployment(stored);
  }
}
