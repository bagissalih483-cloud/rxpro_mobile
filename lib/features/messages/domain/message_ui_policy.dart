class MessageUiPolicy {
  const MessageUiPolicy._();

  static const Map<String, String> topicLabels = {
    'general': 'Genel',
    'appointment': 'Randevu',
    'complaint': 'Şikayet',
    'request': 'Talep',
    'suggestion': 'Öneri',
    'business_customer': 'Müşteri görüşmesi',
  };

  static const Map<String, String> customerNewMessageTopics = {
    'general': 'Genel',
    'appointment': 'Randevu',
    'complaint': 'Şikayet',
    'request': 'Talep',
    'suggestion': 'Öneri',
  };

  static String topicLabel(String? topic) {
    final key = (topic ?? '').trim();
    return topicLabels[key] ?? topicLabels['general']!;
  }

  static bool isClosed(String? status) {
    return (status ?? '').trim().toLowerCase() == 'closed';
  }

  static String statusLabel(String? status) {
    return isClosed(status) ? 'Kapalı' : 'Açık';
  }

  static String inboxRoleLabel({required bool isBusinessOwner}) {
    return isBusinessOwner ? 'Kurumsal gelen kutusu' : 'Bireysel mesajlar';
  }

  static String emptyInboxTitle({required bool isBusinessOwner}) {
    return isBusinessOwner ? 'Henüz müşteri mesajı yok' : 'Henüz mesajınız yok';
  }

  static String emptyInboxText({required bool isBusinessOwner}) {
    return isBusinessOwner
        ? 'Keşif, profil ve randevu akışlarından gelen bireysel kullanıcı mesajları burada görünür.'
        : 'Keşfet sayfasından bir işletme seçip ilk mesajınızı gönderebilirsiniz.';
  }

  static String threadContextTitle({required bool isBusinessOwner}) {
    return isBusinessOwner ? 'Bireysel kullanıcı görüşmesi' : 'İşletme görüşmesi';
  }

  static String threadContextText({required bool isBusinessOwner}) {
    return isBusinessOwner
        ? 'Yanıtlarınız kurumsal hesabınız adına bireysel kullanıcıya iletilir.'
        : 'Yanıtlarınız bireysel hesabınız üzerinden işletmeye iletilir.';
  }

  static String inputHint({required bool isBusinessOwner}) {
    return isBusinessOwner
        ? 'Bireysel kullanıcıya yanıt yaz...'
        : 'İşletmeye mesaj yaz...';
  }

  static String closedThreadNotice({required bool isBusinessOwner}) {
    return isBusinessOwner
        ? 'Bu görüşme kapalı. Yeniden açarak yanıt verebilirsiniz.'
        : 'Bu görüşme işletme tarafından kapatılmış. Yeni yanıt için işletmenin yeniden açması gerekir.';
  }

  static String readReceipt({
    required bool isBusinessOwner,
    required bool readByCustomer,
    required bool readByBusiness,
  }) {
    final seen = isBusinessOwner ? readByCustomer : readByBusiness;
    return seen ? 'Görüldü' : 'Gönderildi';
  }
}
