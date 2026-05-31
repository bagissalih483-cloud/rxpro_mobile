part of 'business_profile_edit_page.dart';

extension _BusinessProfileEditSections on _BusinessProfileEditPageState {
  Widget _coverSection() {
    return InkWell(
      onTap: _pickAndUploadCover,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.grey.shade200,
          image: _profileController.coverUrl == null
              ? null
              : DecorationImage(
                  image: NetworkImage(_profileController.coverUrl!),
                  fit: BoxFit.cover,
                ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.black.withValues(
              alpha: _profileController.coverUrl == null ? 0.02 : 0.25,
            ),
          ),
          child: Center(
            child: _profileController.uploadingCover
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_rounded,
                        size: 34,
                        color: _profileController.coverUrl == null
                            ? const Color(0xFF334155)
                            : Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _profileController.coverUrl == null
                            ? 'Kapak fotoğrafı ekle'
                            : 'Kapak fotoğrafını değiştir',
                        style: TextStyle(
                          color: _profileController.coverUrl == null
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
            backgroundImage: _profileController.logoUrl == null
                ? null
                : NetworkImage(_profileController.logoUrl!),
            child: _profileController.uploadingLogo
                ? const CircularProgressIndicator()
                : _profileController.logoUrl == null
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
    final readiness = BusinessProfileEditPolicy.readiness(
      businessName: _businessNameController.text,
      description: _descriptionController.text,
      city: _cityController.text,
      district: _districtController.text,
      address: _addressController.text,
      workingHours: _workingHoursController.text,
      hasLocation: _profileController.hasLocation,
      hasLogo: _profileController.hasLogo,
      hasCover: _profileController.hasCover,
    );
    final percent = readiness.percent;

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
    final hasLocation = _profileController.hasLocation;

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
                onPressed: _profileController.locatingBusiness
                    ? null
                    : _captureBusinessLocation,
                icon: _profileController.locatingBusiness
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.near_me_outlined),
                label: Text(
                  _profileController.locatingBusiness
                      ? 'Alınıyor'
                      : 'Konumu al',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasLocation
                ? 'Koordinat: ${_profileController.businessLat!.toStringAsFixed(6)}, ${_profileController.businessLng!.toStringAsFixed(6)}'
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
}
