import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/database.dart';

void main() {
  test('database schema includes version 9 template tables', () {
    expect(LocalDatabase.currentSchemaVersionForTest, 9);
    expect(LocalDatabase.templateTableNamesForTest, [
      'templates',
      'template_stages',
      'template_stage_events',
      'template_stage_event_steps',
      'template_notices',
      'template_deployments',
      'template_deployment_stage_progress',
      'template_generated_events',
    ]);
  });
}
