import 'package:flutter/foundation.dart';
import 'package:rxpro_mobile/features/businesses/data/business_customer_repository.dart';

class BusinessCustomersController extends ChangeNotifier {
  String _selectedSegmentId = BusinessCustomerSegments.all.id;
  String _query = '';

  String get selectedSegmentId => _selectedSegmentId;
  String get query => _query;

  List<BusinessCustomerRecord> visibleRecords(
    List<BusinessCustomerRecord> records,
  ) {
    return records
        .where((record) => record.matchesSegment(_selectedSegmentId))
        .where((record) => record.matchesQuery(_query))
        .toList();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void selectSegment(String value) {
    final segmentId = BusinessCustomerSegments.byId(value).id;
    if (_selectedSegmentId == segmentId) return;
    _selectedSegmentId = segmentId;
    notifyListeners();
  }
}

class ManualCustomerFormController extends ChangeNotifier {
  String _segmentId = BusinessCustomerSegments.manual.id;
  bool _campaignConsent = false;
  bool _saving = false;

  String get segmentId => _segmentId;
  bool get campaignConsent => _campaignConsent;
  bool get saving => _saving;

  void selectSegment(String value) {
    final segmentId = BusinessCustomerSegments.byId(value).id;
    if (_segmentId == segmentId) return;
    _segmentId = segmentId;
    notifyListeners();
  }

  void setCampaignConsent(bool value) {
    if (_campaignConsent == value) return;
    _campaignConsent = value;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }
}

class CustomerClassificationController extends ChangeNotifier {
  CustomerClassificationController({
    required String initialSegmentId,
    required bool initialCampaignConsent,
  }) : _segmentId = BusinessCustomerSegments.byId(initialSegmentId).id,
       _campaignConsent = initialCampaignConsent;

  String _segmentId;
  bool _campaignConsent;
  bool _saving = false;

  String get segmentId => _segmentId;
  bool get campaignConsent => _campaignConsent;
  bool get saving => _saving;

  void selectSegment(String value) {
    final segmentId = BusinessCustomerSegments.byId(value).id;
    if (_segmentId == segmentId) return;
    _segmentId = segmentId;
    notifyListeners();
  }

  void setCampaignConsent(bool value) {
    if (_campaignConsent == value) return;
    _campaignConsent = value;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }
}
