import 'package:flutter/foundation.dart';

class BusinessAnalysisController extends ChangeNotifier {
  BusinessAnalysisController({DateTime? anchorDate})
    : _anchorDate = anchorDate ?? DateTime.now();

  int _periodMode = 0;
  DateTime _anchorDate;
  bool _aiLoading = false;
  String _aiReport = '';

  int get periodMode => _periodMode;
  DateTime get anchorDate => _anchorDate;
  bool get aiLoading => _aiLoading;
  String get aiReport => _aiReport;

  DateTime get rangeStart {
    final day = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);

    if (_periodMode == 0) return day;

    if (_periodMode == 1) {
      final mondayOffset = day.weekday - DateTime.monday;
      return day.subtract(Duration(days: mondayOffset));
    }

    return DateTime(_anchorDate.year, _anchorDate.month, 1);
  }

  DateTime get rangeEndExclusive {
    if (_periodMode == 0) return rangeStart.add(const Duration(days: 1));
    if (_periodMode == 1) return rangeStart.add(const Duration(days: 7));
    return DateTime(_anchorDate.year, _anchorDate.month + 1, 1);
  }

  String get periodLabel {
    if (_periodMode == 0) return 'Günlük';
    if (_periodMode == 1) return 'Haftalık';
    return 'Aylık';
  }

  void previousPeriod() {
    _aiReport = '';
    if (_periodMode == 0) {
      _anchorDate = _anchorDate.subtract(const Duration(days: 1));
    } else if (_periodMode == 1) {
      _anchorDate = _anchorDate.subtract(const Duration(days: 7));
    } else {
      _anchorDate = DateTime(_anchorDate.year, _anchorDate.month - 1, 1);
    }
    notifyListeners();
  }

  void nextPeriod() {
    _aiReport = '';
    if (_periodMode == 0) {
      _anchorDate = _anchorDate.add(const Duration(days: 1));
    } else if (_periodMode == 1) {
      _anchorDate = _anchorDate.add(const Duration(days: 7));
    } else {
      _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + 1, 1);
    }
    notifyListeners();
  }

  void selectPeriod(int value) {
    if (_periodMode == value) return;
    _periodMode = value;
    _aiReport = '';
    notifyListeners();
  }

  void setAiLoading(bool value) {
    if (_aiLoading == value) return;
    _aiLoading = value;
    notifyListeners();
  }

  void setAiReport(String value) {
    if (_aiReport == value) return;
    _aiReport = value;
    notifyListeners();
  }
}
