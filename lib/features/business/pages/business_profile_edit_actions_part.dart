part of 'business_profile_edit_page.dart';

extension _BusinessProfileEditActions on _BusinessProfileEditPageState {
  Future<void> _loadBusiness() async {
    try {
      final data = await _editRepository.fetchBusinessProfile(
        widget.businessId,
      );

      _businessNameController.text = BusinessProfileEditPolicy.firstNonEmpty([
        data[FirestoreFields.businessName],
        data[FirestoreFields.name],
        data[FirestoreFields.companyName],
        data[FirestoreFields.displayName],
      ]);

      final category = BusinessCategories.fallbackFromDynamic(
        categoryId: data['categoryId']?.toString(),
        categoryLabel: data[FirestoreFields.categoryLabel]?.toString(),
        category: data[FirestoreFields.category]?.toString(),
        businessCategory: data[FirestoreFields.businessCategory]?.toString(),
      );
      _phoneController.text = BusinessProfileEditPolicy.firstNonEmpty([
        data[FirestoreFields.phone],
        data[FirestoreFields.phoneNumber],
        data[FirestoreFields.nationalPhoneNumber],
        data[FirestoreFields.internationalPhoneNumber],
      ]);
      _businessEmailController.text = BusinessProfileEditPolicy.firstNonEmpty([
        data[FirestoreFields.businessEmail],
        data[FirestoreFields.contactEmail],
        data[FirestoreFields.email],
      ]);
      _websiteController.text = BusinessProfileEditPolicy.firstNonEmpty([
        data[FirestoreFields.websiteUrl],
        data[FirestoreFields.websiteUri],
        data['website'],
      ]);
      _instagramController.text = (data[FirestoreFields.instagramUrl] ?? '')
          .toString();
      _whatsappController.text = (data[FirestoreFields.whatsappPhone] ?? '')
          .toString();
      _descriptionController.text = (data[FirestoreFields.description] ?? '')
          .toString();
      _cityController.text = (data[FirestoreFields.city] ?? '').toString();
      _districtController.text = (data[FirestoreFields.district] ?? '')
          .toString();
      _addressController.text = (data[FirestoreFields.address] ?? '')
          .toString();
      _workingHoursController.text = (data[FirestoreFields.workingHours] ?? '')
          .toString();

      final location = BusinessLocationParser.fromMap(data);
      _profileController.applyLoadedProfile(
        categoryId: category.id,
        logoUrl: (data[FirestoreFields.logoUrl] ?? '').toString(),
        coverUrl: (data[FirestoreFields.coverUrl] ?? '').toString(),
        businessLat: location.lat,
        businessLng: location.lng,
      );
    } catch (e) {
      if (!mounted) return;

      _profileController.finishLoading();
      _showSnack('Kurumsal profil bilgileri alınamadı: $e');
    }
  }

  Future<void> _pickAndUploadLogo() async {
    if (!_profileController.canStartMediaUpload) return;

    try {
      final file = await AppImageUploadService.pickFromGallery();
      if (file == null) return;

      _profileController.setLogoUploading(true);

      final url = await AppImageUploadService.uploadBusinessLogo(
        businessId: widget.businessId,
        ownerUid: _requireCurrentUid(),
        file: file,
      );

      await _editRepository.updateBusinessLogoUrl(
        businessId: widget.businessId,
        logoUrl: url,
      );

      if (!mounted) return;

      _profileController.applyLogoUrl(url);
      _showSnack('Kurumsal profil fotoğrafı güncellendi.');
    } catch (e) {
      if (!mounted) return;

      _profileController.setLogoUploading(false);
      _showSnack('Profil fotoğrafı yüklenemedi: $e');
    }
  }

  Future<void> _pickAndUploadCover() async {
    if (!_profileController.canStartMediaUpload) return;

    try {
      final file = await AppImageUploadService.pickFromGallery();
      if (file == null) return;

      _profileController.setCoverUploading(true);

      final url = await AppImageUploadService.uploadBusinessCover(
        businessId: widget.businessId,
        ownerUid: _requireCurrentUid(),
        file: file,
      );

      await _editRepository.updateBusinessCoverUrl(
        businessId: widget.businessId,
        coverUrl: url,
      );

      if (!mounted) return;

      _profileController.applyCoverUrl(url);
      _showSnack('Kapak fotoğrafı güncellendi.');
    } catch (e) {
      if (!mounted) return;

      _profileController.setCoverUploading(false);
      _showSnack('Kapak fotoğrafı yüklenemedi: $e');
    }
  }

  Future<void> _captureBusinessLocation() async {
    if (_profileController.locatingBusiness || _profileController.saving) {
      return;
    }

    _profileController.setLocatingBusiness(true);

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showSnack('Telefon konum servisi kapalı. Lütfen konumu açın.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Konum izni verilmedi.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      _profileController.applyLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await _editRepository.updateBusinessLocation(
        businessId: widget.businessId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _showSnack(
        'İşletme konumu kaydedildi. Keşfet sıralaması bu konumu kullanacak.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Konum alınamadı: $e');
    } finally {
      if (mounted) _profileController.setLocatingBusiness(false);
    }
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileController.saving) return;

    _profileController.setSaving(true);

    try {
      final category =
          BusinessCategories.byId(_profileController.categoryId) ??
          BusinessCategories.values.last;

      await _editRepository.updateBusinessProfileInfo(
        businessId: widget.businessId,
        businessName: _businessNameController.text.trim(),
        categoryId: category.id,
        categoryLabel: category.label,
        categoryKeywords: category.keywords,
        phone: _phoneController.text.trim(),
        businessEmail: _businessEmailController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        instagramUrl: _instagramController.text.trim(),
        whatsappPhone: _whatsappController.text.trim(),
        description: _descriptionController.text.trim(),
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        address: _addressController.text.trim(),
        workingHours: _workingHoursController.text.trim(),
        latitude: _profileController.businessLat,
        longitude: _profileController.businessLng,
      );

      if (!mounted) return;

      _showSnack('Kurumsal profil güncellendi.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Kaydetme sırasında hata oluştu: $e');
    } finally {
      if (mounted) _profileController.setSaving(false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _requireCurrentUid() {
    final uid = _authService.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      throw StateError('Görsel yüklemek için oturum gerekir.');
    }
    return uid;
  }
}
