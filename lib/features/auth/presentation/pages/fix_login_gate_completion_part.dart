part of 'fix_login_gate_page.dart';

extension _FixLoginGateCompletionActions on _FixLoginGatePageState {
  Future<void> _completeIndividualAuth({
    required User user,
    required String email,
    required String phone,
  }) async {
    final typedName = fullNameController.text.trim();
    final googleName = user.displayName?.trim() ?? '';
    final displayName = isRegister && typedName.isNotEmpty
        ? typedName
        : (googleName.isNotEmpty ? googleName : 'Bireysel Kullanıcı');

    await user.updateDisplayName(displayName);

    await firestoreService.saveUser(
      AppUserModel(
        uid: user.uid,
        email: email,
        phone: phone.isEmpty ? phoneController.text.trim() : phone,
        displayName: displayName,
        role: UserRole.customer,
        accountStatus: AccountStatus.active,
        emailVerified: user.emailVerified,
        phoneVerified: phone.isNotEmpty,
      ),
    );

    // Bireysel kullanıcı rolü kesin yazılır; eski kurumsal alanlar temizlenir.
    await _loginGateRepository.ensureIndividualUserDocument(
      user: user,
      email: email,
      phone: phone.isEmpty ? phoneController.text.trim() : phone,
      displayName: displayName,
      city: cityController.text,
      district: districtController.text,
      phoneVerified: phone.isNotEmpty,
      recordLegalAcceptance: isRegister,
    );

    if (isRegister) {
      unawaited(
        AppObservabilityService.instance.logRegistrationCompleted(
          accountType: 'individual',
        ),
      );
    }
  }

  Future<void> _completeCorporateAuth({
    required User user,
    required String email,
    required String phone,
  }) async {
    final typedOwnerName = corporateOwnerController.text.trim();
    final googleName = user.displayName?.trim() ?? '';
    final ownerName = isRegister && typedOwnerName.isNotEmpty
        ? typedOwnerName
        : (googleName.isNotEmpty ? googleName : 'Kurumsal Yetkili');

    await user.updateDisplayName(ownerName);

    final finalPhone = phone.isEmpty ? phoneController.text.trim() : phone;
    final businessContext = await _resolveCorporateBusinessContext(user);
    final businessId = isRegister
        ? 'business_${user.uid}'
        : businessContext['businessId']!;
    final businessName = isRegister
        ? corporateNameController.text.trim()
        : businessContext['businessName']!;

    await firestoreService.saveUser(
      AppUserModel(
        uid: user.uid,
        email: email,
        phone: finalPhone,
        displayName: ownerName,
        role: UserRole.businessOwner,
        accountStatus: AccountStatus.active,
        emailVerified: user.emailVerified,
        phoneVerified: phone.isNotEmpty,
      ),
    );

    if (isRegister) {
      final address = corporateAddressController.text.trim();

      await firestoreService.saveBusiness(
        BusinessAccountModel(
          id: businessId,
          ownerUid: user.uid,
          businessName: businessName,
          category: _controller.selectedCategory.label,
          phone: finalPhone,
          address: address.isEmpty
              ? 'Adres bilgisi daha sonra tamamlanacak'
              : address,
          businessStatus: BusinessStatus.active,
          ownerEmailVerified: user.emailVerified,
          ownerPhoneVerified: phone.isNotEmpty,
          adminApproved: true,
        ),
      );

      await _loginGateRepository.ensureCorporateBusinessDocument(
        user: user,
        businessId: businessId,
        businessName: businessName,
        city: cityController.text,
        district: districtController.text,
        categoryData: _controller.selectedCategory.toFirestore(),
      );
    }

    // Kurumsal rol kesin yazılır; AppGate artık bu alanlara göre shell seçer.
    await _loginGateRepository.ensureCorporateOwnerUserDocument(
      user: user,
      email: email,
      phone: phone.isEmpty ? phoneController.text.trim() : phone,
      businessId: businessId,
      businessName: businessName,
      ownerName: ownerName,
      city: cityController.text,
      district: districtController.text,
      phoneVerified: phone.isNotEmpty,
      recordLegalAcceptance: isRegister,
    );

    if (isRegister) {
      unawaited(
        AppObservabilityService.instance.logRegistrationCompleted(
          accountType: 'corporate',
        ),
      );
    }
  }

  Future<Map<String, String>> _resolveCorporateBusinessContext(
    User user,
  ) async {
    final context = await _loginGateRepository.resolveCorporateBusinessContext(
      user: user,
      fallbackBusinessName: corporateNameController.text.trim(),
    );

    return <String, String>{
      'businessId': context.businessId,
      'businessName': context.businessName,
    };
  }
}
