import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/uploads/app_image_upload_service.dart';
import 'package:rxpro_mobile/features/public_home/data/account_user_profile_repository.dart';
import 'package:rxpro_mobile/features/public_home/domain/account_user_profile_policy.dart';
import 'package:rxpro_mobile/features/public_home/presentation/account_entry_lite_controller.dart';
import 'package:rxpro_mobile/features/public_home/presentation/widgets/account_entry_cards.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountUserProfileLitePage extends StatefulWidget {
  const AccountUserProfileLitePage({super.key, required this.user});

  final User user;

  @override
  State<AccountUserProfileLitePage> createState() =>
      _AccountUserProfileLitePageState();
}

class _AccountUserProfileLitePageState
    extends State<AccountUserProfileLitePage> {
  final _formKey = GlobalKey<FormState>();
  final AccountUserProfileRepository _repository =
      AccountUserProfileRepository();
  final AccountUserProfileLiteController _controller =
      AccountUserProfileLiteController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.fetchProfile(widget.user);
      if (!mounted) return;

      _displayNameController.text = data.displayName;
      _phoneController.text = data.phone;
      _cityController.text = data.city;
      _districtController.text = data.district;
      _controller.applyLoaded(data);
    } catch (e) {
      if (!mounted) return;

      _controller.completeLoading();
      _showSnack('Profil bilgileri alınamadı: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_controller.saving) return;

    _controller.setSaving(true);

    try {
      final input = AccountUserProfilePolicy.normalizeUpdate(
        displayName: _displayNameController.text,
        phone: _phoneController.text,
        city: _cityController.text,
        district: _districtController.text,
        photoUrl: _controller.photoUrl,
      );

      await _repository.updateProfile(
        uid: widget.user.uid,
        displayName: input.displayName,
        phone: input.phone,
        city: input.city,
        district: input.district,
        photoUrl: input.photoUrl,
      );

      if (!mounted) return;
      _showSnack('Profil güncellendi.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Profil kaydedilemedi: $e');
    } finally {
      if (mounted) _controller.setSaving(false);
    }
  }

  Future<void> _pickAvatar() async {
    if (_controller.uploadingAvatar || _controller.saving) return;

    try {
      final file = await AppImageUploadService.pickFromGallery();
      if (file == null) return;

      _controller.setUploadingAvatar(true);

      final url = await AppImageUploadService.uploadUserAvatar(
        uid: widget.user.uid,
        file: file,
      );

      final input = AccountUserProfilePolicy.normalizeUpdate(
        displayName: _displayNameController.text,
        phone: _phoneController.text,
        city: _cityController.text,
        district: _districtController.text,
        photoUrl: url,
      );

      await _repository.updateProfile(
        uid: widget.user.uid,
        displayName: input.displayName,
        phone: input.phone,
        city: input.city,
        district: input.district,
        photoUrl: input.photoUrl,
      );

      if (!mounted) return;

      _controller.applyAvatarUrl(url);
      _showSnack('Profil fotoğrafı güncellendi.');
    } catch (e) {
      if (!mounted) return;

      _controller.setUploadingAvatar(false);
      _showSnack('Fotoğraf yüklenemedi: $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Profilim')),
        body: _controller.loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    _profileHeader(),
                    const SizedBox(height: 14),
                    AccountInfoCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Hesap doğrulama',
                      text: AccountUserProfilePolicy.verificationText(
                        email: _controller.email,
                        authPhoneNumber: widget.user.phoneNumber,
                        profilePhone: _phoneController.text,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle('Kişisel bilgiler'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _displayNameController,
                      autofillHints: const [AutofillHints.name],
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'Ad Soyad',
                        hint: 'Örn: Ayşe Demir',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: AccountUserProfilePolicy.validateDisplayName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'İletişim telefonu',
                        hint: 'Örn: 05xx xxx xx xx',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                              hint: 'İstanbul',
                              icon: Icons.location_city_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _districtController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDecoration(
                              label: 'İlçe',
                              hint: 'Kadıköy',
                              icon: Icons.place_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _controller.saving ? null : _save,
                        icon: _controller.saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _controller.saving
                              ? 'Kaydediliyor...'
                              : 'Profili Kaydet',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _profileHeader() {
    final photoUrl = _controller.photoUrl;
    final hasPhoto = photoUrl.trim().isNotEmpty;
    final uploadingAvatar = _controller.uploadingAvatar;
    final avatarActionDisabled = uploadingAvatar || _controller.saving;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: avatarActionDisabled ? null : _pickAvatar,
            borderRadius: BorderRadius.circular(34),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFFE0F2FE),
              backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
              child: uploadingAvatar
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : hasPhoto
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF0369A1),
                      size: 34,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bireysel profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keşfet, randevu ve mesajlaşma akışında görünen temel bilgilerin.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: avatarActionDisabled ? null : _pickAvatar,
            icon: const Icon(Icons.photo_camera_outlined),
            tooltip: 'Fotoğraf değiştir',
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
    required IconData icon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}

class AccountAppSettingsLitePage extends StatefulWidget {
  const AccountAppSettingsLitePage({super.key});

  @override
  State<AccountAppSettingsLitePage> createState() =>
      _AccountAppSettingsLitePageState();
}

class _AccountAppSettingsLitePageState
    extends State<AccountAppSettingsLitePage> {
  static const _notificationKey = 'fix_settings_notifications_enabled';
  static const _campaignKey = 'fix_settings_campaign_updates_enabled';
  static const _routeKey = 'fix_settings_route_distance_enabled';

  final AccountAppSettingsLiteController _controller =
      AccountAppSettingsLiteController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    _controller.applyLoaded(
      notifications: prefs.getBool(_notificationKey) ?? true,
      campaigns: prefs.getBool(_campaignKey) ?? true,
      routeDistance: prefs.getBool(_routeKey) ?? true,
    );
  }

  Future<void> _set(String key, bool value, ValueChanged<bool> apply) async {
    apply(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayar kaydedildi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Uygulama Ayarları')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          const AccountInfoCard(
            icon: Icons.settings_outlined,
            title: 'Kullanım tercihleri',
            text:
                'Bu tercihler cihazda saklanır ve uygulama deneyimini sadeleştirmek için kullanılır.',
          ),
          const SizedBox(height: 12),
          if (_controller.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _SettingSwitchTile(
              icon: Icons.notifications_none_rounded,
              title: 'Bildirimleri göster',
              subtitle: 'Randevu, mesaj ve sistem bildirimleri görünür kalsın.',
              value: _controller.notifications,
              onChanged: (value) => _set(
                _notificationKey,
                value,
                _controller.setNotifications,
              ),
            ),
            _SettingSwitchTile(
              icon: Icons.local_offer_outlined,
              title: 'Fırsat güncellemeleri',
              subtitle:
                  'Takip edilen işletmelerden fırsat ve duyuru almayı açık tut.',
              value: _controller.campaigns,
              onChanged: (value) =>
                  _set(_campaignKey, value, _controller.setCampaigns),
            ),
            _SettingSwitchTile(
              icon: Icons.route_outlined,
              title: 'Yol mesafesi göstergesi',
              subtitle:
                  'Keşfette uygun işletmeler için araçla mesafe bilgisini göster.',
              value: _controller.routeDistance,
              onChanged: (value) =>
                  _set(_routeKey, value, _controller.setRouteDistance),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: const Color(0xFF0F766E)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
