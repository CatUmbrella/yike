import 'package:flutter/foundation.dart';

import '../../models/pomodoro_models.dart';
import '../../repositories/pomodoro_repository.dart';

class PomodoroHistoryController extends ChangeNotifier {
  PomodoroHistoryController({PomodoroRepository? repository})
    : _repository = repository ?? PomodoroRepository();

  final PomodoroRepository _repository;

  bool loading = true;
  Object? error;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String searchQuery = '';
  List<PomodoroHistorySection> sections = const [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      sections = await _repository.loadHistory(
        year: selectedMonth.year,
        month: selectedMonth.month,
        keyword: searchQuery,
      );
    } catch (err) {
      error = err;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectMonth(DateTime month) async {
    selectedMonth = DateTime(month.year, month.month);
    await load();
  }

  Future<void> updateSearchQuery(String value) async {
    searchQuery = value;
    await load();
  }
}
