import 'package:flutter/foundation.dart';

class BulkMessageCreateController extends ChangeNotifier {
  BulkMessageCreateController({
    required List<String> targets,
    required String initialTarget,
    required String initialChannel,
    bool consentOnly = true,
  }) : targets = List.unmodifiable(targets),
       _target = initialTarget,
       _channel = initialChannel,
       _consentOnly = consentOnly;

  final List<String> targets;

  String _target;
  String _channel;
  bool _consentOnly;
  bool _saving = false;
  int _textVersion = 0;

  String get target => _target;
  String get channel => _channel;
  bool get consentOnly => _consentOnly;
  bool get saving => _saving;
  int get textVersion => _textVersion;

  void refreshTextInputs() {
    _textVersion += 1;
    notifyListeners();
  }

  void selectTarget(String value) {
    if (_target == value) return;
    _target = value;
    notifyListeners();
  }

  void selectChannel(String value) {
    if (_channel == value) return;
    _channel = value;
    notifyListeners();
  }

  void setConsentOnly(bool value) {
    if (_consentOnly == value) return;
    _consentOnly = value;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    _saving = value;
    notifyListeners();
  }
}
