import 'package:flutter/foundation.dart';

import 'domain/business_campaign_item_view_model.dart';

class BusinessCampaignsController extends ChangeNotifier {
  BusinessCampaignsController({
    required Future<List<BusinessCampaignItemViewModel>> Function() load,
  }) : _load = load {
    _future = _load();
  }

  final Future<List<BusinessCampaignItemViewModel>> Function() _load;
  late Future<List<BusinessCampaignItemViewModel>> _future;
  int _selectedTab = 0;
  bool _sendingBulkDraft = false;

  Future<List<BusinessCampaignItemViewModel>> get future => _future;
  int get selectedTab => _selectedTab;
  bool get sendingBulkDraft => _sendingBulkDraft;

  Future<void> refresh() async {
    final next = _load();
    _future = next;
    notifyListeners();
    await next;
  }

  void selectTab(int value) {
    if (_selectedTab == value) return;
    _selectedTab = value;
    notifyListeners();
  }

  void setSendingBulkDraft(bool value) {
    if (_sendingBulkDraft == value) return;
    _sendingBulkDraft = value;
    notifyListeners();
  }
}
