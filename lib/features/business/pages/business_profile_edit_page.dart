import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';
import 'package:rxpro_mobile/core/businesses/business_location_data.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';
import 'package:rxpro_mobile/core/uploads/app_image_upload_service.dart';
import 'package:rxpro_mobile/features/business/data/business_profile_edit_repository.dart';
import 'package:rxpro_mobile/features/business/domain/business_profile_edit_policy.dart';
import 'package:rxpro_mobile/features/business/presentation/business_profile_edit_controller.dart';

/// Business profile edit page keeps document writes behind a repository.

part 'business_profile_edit_actions_part.dart';
part 'business_profile_edit_sections_part.dart';
part 'business_profile_edit_appbar_part.dart';

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
  final BusinessProfileEditController _profileController =
      BusinessProfileEditController();

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

  @override
  void initState() {
    super.initState();
    _loadBusiness();
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
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _profileController,
      builder: (context, _) {
        if (_profileController.loading) {
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                    validator: BusinessProfileEditPolicy.validateBusinessName,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _profileController.categoryId,
                    items: BusinessCategories.values
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _profileController.saving
                        ? null
                        : (value) {
                            if (value == null) return;
                            _profileController.setCategoryId(value);
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
                    validator: BusinessProfileEditPolicy.validateOptionalEmail,
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
                    validator: BusinessProfileEditPolicy.validateOptionalUrl,
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
                    validator: BusinessProfileEditPolicy.validateDescription,
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
                          validator: (value) =>
                              BusinessProfileEditPolicy.validateRequired(
                                value,
                                'İl giriniz.',
                              ),
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
                          validator: (value) =>
                              BusinessProfileEditPolicy.validateRequired(
                                value,
                                'İlçe giriniz.',
                              ),
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
                    validator: (value) =>
                        BusinessProfileEditPolicy.validateRequired(
                          value,
                          'Adres boş bırakılamaz.',
                        ),
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
                    validator: (value) =>
                        BusinessProfileEditPolicy.validateRequired(
                          value,
                          'Çalışma saatleri boş bırakılamaz.',
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _profileController.saving
                          ? null
                          : _saveBusiness,
                      icon: _profileController.saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _profileController.saving
                            ? 'Kaydediliyor...'
                            : 'Profili Kaydet',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
