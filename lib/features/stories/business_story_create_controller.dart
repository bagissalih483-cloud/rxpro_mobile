import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class BusinessStoryCreateController extends ChangeNotifier {
  XFile? _selectedImage;
  bool _publishing = false;

  XFile? get selectedImage => _selectedImage;
  bool get publishing => _publishing;

  void selectImage(XFile file) {
    _selectedImage = file;
    notifyListeners();
  }

  void setPublishing(bool value) {
    if (value == _publishing) return;
    _publishing = value;
    notifyListeners();
  }
}
