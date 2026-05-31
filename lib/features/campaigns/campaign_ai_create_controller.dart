import 'package:flutter/foundation.dart';

class CampaignAiCreateController extends ChangeNotifier {
  String _category = 'Genel';
  String _tone = 'Modern';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _generating = false;
  bool _publishing = false;
  String _resolvedBusinessId = '';
  String _resolvedBusinessName = 'İşletme';
  String _generatedTitle = '';
  String _generatedBody = '';
  String _generatedCta = '';
  String _lastPublishedKey = '';

  String get category => _category;
  String get tone => _tone;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get generating => _generating;
  bool get publishing => _publishing;
  String get resolvedBusinessId => _resolvedBusinessId;
  String get resolvedBusinessName => _resolvedBusinessName;
  String get generatedTitle => _generatedTitle;
  String get generatedBody => _generatedBody;
  String get generatedCta => _generatedCta;
  String get lastPublishedKey => _lastPublishedKey;

  bool canGenerate({required String offer, required String audience}) {
    return offer.trim().isNotEmpty &&
        audience.trim().isNotEmpty &&
        !_generating;
  }

  bool get canPublish {
    return _generatedTitle.trim().isNotEmpty &&
        _generatedBody.trim().isNotEmpty &&
        !_publishing;
  }

  void applyBusinessContext({
    required String businessId,
    required String businessName,
  }) {
    _resolvedBusinessId = businessId.trim();
    _resolvedBusinessName = _normalizeBusinessName(businessName);
    notifyListeners();
  }

  void setCategory(String value) {
    final next = value.trim().isEmpty ? 'Genel' : value;
    if (_category == next) return;
    _category = next;
    notifyListeners();
  }

  void setTone(String value) {
    final next = value.trim().isEmpty ? 'Modern' : value;
    if (_tone == next) return;
    _tone = next;
    notifyListeners();
  }

  void setDate({required bool start, required DateTime picked}) {
    if (start) {
      _startDate = picked;
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate.add(const Duration(days: 7));
      }
    } else {
      _endDate = picked.isBefore(_startDate) ? _startDate : picked;
    }
    notifyListeners();
  }

  void beginGenerate() {
    _generating = true;
    notifyListeners();
  }

  void applyGenerated({
    required String title,
    required String body,
    required String cta,
  }) {
    _generatedTitle = title;
    _generatedBody = body;
    _generatedCta = cta;
    _lastPublishedKey = '';
    notifyListeners();
  }

  void finishGenerate() {
    if (!_generating) return;
    _generating = false;
    notifyListeners();
  }

  void beginPublish() {
    _publishing = true;
    notifyListeners();
  }

  void markPublished(String key) {
    _lastPublishedKey = key;
    notifyListeners();
  }

  void finishPublish() {
    if (!_publishing) return;
    _publishing = false;
    notifyListeners();
  }

  String publishKey() {
    return [
      _resolvedBusinessId,
      _generatedTitle.trim().toLowerCase(),
      _generatedBody.trim().toLowerCase(),
      _generatedCta.trim().toLowerCase(),
      _startDate.toIso8601String(),
      _endDate.toIso8601String(),
    ].join('|');
  }

  static String _normalizeBusinessName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'İşletme' : trimmed;
  }
}
