import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';
import 'package:rxpro_mobile/core/businesses/business_location_data.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';
import 'package:rxpro_mobile/core/uploads/app_image_upload_service.dart';
import 'package:rxpro_mobile/features/business/data/business_profile_edit_repository.dart';

/// Business profile edit page keeps document writes behind a repository.
class BusinessProfileEditPage extends StatefulWidget {
  const BusinessProfileEditPage({super.key, required this.businessId});

  final String businessId;

  @override
  State<BusinessProfileEditPage> createState() =>
      _BusinessProfileEditPageState();
}

class _BusinessProfileEditPageState extends State<BusinessProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final BusinessProfileEditRepository _editRepository =
      BusinessProfileEditRepository();
  final AuthService _authService = AuthService();

  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressController = TextEditingController();
  final _workingHoursController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingLogo = false;
  bool _uploadingCover = false;
  bool _locatingBusiness = false;

  String? _logoUrl;
  String? _coverUrl;
  double? _businessLat;
  double? _businessLng;
  String _categoryId = BusinessCategories.values.first.id;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final data = await _editRepository.fetchBusinessProfile(
        widget.businessId,
      );

      _businessNameController.text = _firstNonEmpty([
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
      _categoryId = category.id;

      _phoneController.text = _firstNonEmpty([
        data[FirestoreFields.phone],
        data[FirestoreFields.phoneNumber],
        data[FirestoreFields.nationalPhoneNumber],
        data[FirestoreFields.internationalPhoneNumber],
      ]);
      _businessEmailController.text = _firstNonEmpty([
        data[FirestoreFields.businessEmail],
        data[FirestoreFields.contactEmail],
        data[FirestoreFields.email],
      ]);
      _websiteController.text = _firstNonEmpty([
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
      _businessLat = location.lat;
      _businessLng = location.lng;

      _logoUrl = (data[FirestoreFields.logoUrl] ?? '').toString().trim();
      _coverUrl = (data[FirestoreFields.coverUrl] ?? '').toString().trim();

      if (_logoUrl!.isEmpty) _logoUrl = null;
      if (_coverUrl!.isEmpty) _coverUrl = null;

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showSnack('Kurumsal profil bilgileri alınamadı: $e');
    }
  }

  Future<void> _pickAndUploadLogo() async {
    if (_uploadingLogo || _saving) return;

    try {
      final file = await AppImageUploadService.pickFromGallery();
      if (file == null) return;

      setState(() => _uploadingLogo = true);

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

      setState(() {
        _logoUrl = url;
        _uploadingLogo = false;
      });
      _showSnack('Kurumsal profil fotoğrafı güncellendi.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _uploadingLogo = false);
      _showSnack('Profil fotoğrafı yüklenemedi: $e');
    }
  }

  Future<void> _pickAndUploadCover() async {
    if (_uploadingCover || _saving) return;

    try {
      final file = await AppImageUploadService.pickFromGallery();
      if (file == null) return;

      setState(() => _uploadingCover = true);

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

      setState(() {
        _coverUrl = url;
        _uploadingCover = false;
      });
      _showSnack('Kapak fotoğrafı güncellendi.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _uploadingCover = false);
      _showSnack('Kapak fotoğrafı yüklenemedi: $e');
    }
  }

  Future<void> _captureBusinessLocation() async {
    if (_locatingBusiness || _saving) return;

    setState(() => _locatingBusiness = true);

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

      setState(() {
        _businessLat = position.latitude;
        _businessLng = position.longitude;
      });
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
      if (mounted) setState(() => _locatingBusiness = false);
    }
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final category =
          BusinessCategories.byId(_categoryId) ??
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
        latitude: _businessLat,
        longitude: _businessLng,
      );

      if (!mounted) return;

      _showSnack('Kurumsal profil güncellendi.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Kaydetme sırasında hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
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

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _businessEmailController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _whatsappController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: const _BusinessEditAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const _BusinessEditAppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _coverSection(),
              const SizedBox(height: 16),
              _logoSection(),
              const SizedBox(height: 18),
              _readinessCard(),
              const SizedBox(height: 18),
              _sectionTitle('Vitrin kimliği'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _businessNameController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'İşletme adı',
                  hint: 'Örn: Fix Beauty Studio',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) {
                    return 'İşletme adı en az 2 karakter olmalıdır.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                items: BusinessCategories.values
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _categoryId = value);
                      },
                decoration: _inputDecoration(
                  label: 'Kategori',
                  hint: 'İşletme kategorisi',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Telefon',
                  hint: 'Örn: 05xx xxx xx xx',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _businessEmailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'İşletme e-postası',
                  hint: 'ornek@fix.com',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Web sitesi',
                  hint: 'https://...',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _instagramController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'Instagram',
                        hint: '@isletmeadi',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'WhatsApp',
                        hint: '05xx...',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle('Tanıtım bilgileri'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  label: 'Kurumsal profil açıklaması',
                  hint:
                      'İşletmenizi, uzmanlığınızı ve sunduğunuz hizmetleri yazın.',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Kurumsal profil açıklaması boş bırakılamaz.';
                  }
                  if (text.length < 10) {
                    return 'Açıklama biraz daha detaylı olmalıdır.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      autofillHints: const [AutofillHints.addressCity],
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'İl',
                        hint: 'Şanlıurfa',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return 'İl giriniz.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'İlçe',
                        hint: 'Haliliye',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'İlçe giriniz.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _addressController,
                autofillHints: const [AutofillHints.fullStreetAddress],
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  label: 'Adres',
                  hint: 'Mahalle, cadde, sokak, bina bilgisi',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Adres boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _businessLocationCard(),
              const SizedBox(height: 14),
              TextFormField(
                controller: _workingHoursController,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  label: 'Çalışma saatleri',
                  hint: 'Örn: Pazartesi - Cumartesi 09:00 - 20:00',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Çalışma saatleri boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveBusiness,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Kaydediliyor...' : 'Profili Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverSection() {
    return InkWell(
      onTap: _pickAndUploadCover,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.grey.shade200,
          image: _coverUrl == null
              ? null
              : DecorationImage(
                  image: NetworkImage(_coverUrl!),
                  fit: BoxFit.cover,
                ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.black.withValues(
              alpha: _coverUrl == null ? 0.02 : 0.25,
            ),
          ),
          child: Center(
            child: _uploadingCover
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_rounded,
                        size: 34,
                        color: _coverUrl == null
                            ? const Color(0xFF334155)
                            : Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _coverUrl == null
                            ? 'Kapak fotoğrafı ekle'
                            : 'Kapak fotoğrafını değiştir',
                        style: TextStyle(
                          color: _coverUrl == null
                              ? const Color(0xFF334155)
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _logoSection() {
    return Row(
      children: [
        InkWell(
          onTap: _pickAndUploadLogo,
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFEFF6FF),
            backgroundImage: _logoUrl == null ? null : NetworkImage(_logoUrl!),
            child: _uploadingLogo
                ? const CircularProgressIndicator()
                : _logoUrl == null
                ? const Icon(
                    Icons.storefront_rounded,
                    size: 34,
                    color: Color(0xFF2563EB),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Kurumsal profil fotoğrafı'),
              const SizedBox(height: 4),
              const Text(
                'Logoya dokunarak galeriden yeni fotoğraf seçebilirsiniz.',
                style: TextStyle(color: Colors.black54, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _readinessCard() {
    final completed = <bool>[
      _businessNameController.text.trim().isNotEmpty,
      _descriptionController.text.trim().length >= 10,
      _cityController.text.trim().isNotEmpty,
      _districtController.text.trim().isNotEmpty,
      _addressController.text.trim().isNotEmpty,
      _workingHoursController.text.trim().isNotEmpty,
      _businessLat != null && _businessLng != null,
      _logoUrl != null && _logoUrl!.isNotEmpty,
      _coverUrl != null && _coverUrl!.isNotEmpty,
    ].where((item) => item).length;
    final percent = ((completed / 9) * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFDCFCE7),
            child: Text(
              '%$percent',
              style: const TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vitrin hazırlığı',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Ad, kategori, açıklama, konum ve görseller keşfet kalitesini belirler.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _businessLocationCard() {
    final hasLocation = _businessLat != null && _businessLng != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: Color(0xFF216A6D)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Keşfet konumu',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _locatingBusiness ? null : _captureBusinessLocation,
                icon: _locatingBusiness
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.near_me_outlined),
                label: Text(_locatingBusiness ? 'Alınıyor' : 'Konumu al'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasLocation
                ? 'Koordinat: ${_businessLat!.toStringAsFixed(6)}, ${_businessLng!.toStringAsFixed(6)}'
                : 'İşletmenin keşfette doğru sıralanması ve yol tarifi alabilmesi için işletme içindeyken konumu alın.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF216A6D), width: 1.4),
      ),
    );
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return '';
  }
}

class _BusinessEditAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _BusinessEditAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Kurumsal Profil Düzenle'),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
