import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class BusinessProfilePostCreateController extends ChangeNotifier {
  XFile? _selectedImage;
  bool _saving = false;

  XFile? get selectedImage => _selectedImage;
  bool get saving => _saving;
  bool get hasImage => _selectedImage != null;

  void selectImage(XFile file) {
    _selectedImage = file;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (value == _saving) return;
    _saving = value;
    notifyListeners();
  }
}
