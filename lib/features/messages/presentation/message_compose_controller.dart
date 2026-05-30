import 'package:flutter/material.dart';

class MessageComposeController extends ChangeNotifier {
  MessageComposeController({
    String initialText = '',
    String initialTopic = 'general',
  }) : textController = TextEditingController(text: initialText),
       _topic = initialTopic;

  final TextEditingController textController;

  String _topic;
  bool _sending = false;

  String get topic => _topic;
  bool get sending => _sending;
  String get trimmedText => textController.text.trim();
  bool get canSend => !_sending && trimmedText.isNotEmpty;

  void setTopic(String value) {
    final clean = value.trim();
    if (clean.isEmpty || clean == _topic) return;
    _topic = clean;
    notifyListeners();
  }

  void setSending(bool value) {
    if (_sending == value) return;
    _sending = value;
    notifyListeners();
  }

  void clearText() {
    if (textController.text.isEmpty) return;
    textController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
