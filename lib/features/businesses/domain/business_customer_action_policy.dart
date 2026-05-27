class BusinessCustomerActionPolicy {
  const BusinessCustomerActionPolicy._();

  static bool canDirectMessage(String? customerUid) {
    final normalized = (customerUid ?? '').trim();
    return normalized.isNotEmpty && normalized != '-';
  }

  static String directMessageUnavailableText() {
    return 'Bu müşteri manuel kayıt olduğu için bireysel kullanıcı hesabı bağlı değil.';
  }

  static String bulkAudienceLabel({
    required String selectedSegmentId,
    required String segmentLabel,
  }) {
    return selectedSegmentId == 'all'
        ? 'Müşteri defteri: tüm müşteriler'
        : 'Müşteri defteri: $segmentLabel';
  }
}
