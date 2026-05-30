class MessageUiPolicy {
  const MessageUiPolicy._();

  static const Map<String, String> topicLabels = {
    'general': 'Genel',
    'appointment': 'Randevu',
    'complaint': 'Sikayet',
    'request': 'Talep',
    'suggestion': 'Oneri',
    'business_customer': 'Musteri gorusmesi',
  };

  static const Map<String, String> customerNewMessageTopics = {
    'general': 'Genel',
    'appointment': 'Randevu',
    'complaint': 'Sikayet',
    'request': 'Talep',
    'suggestion': 'Oneri',
  };

  static String topicLabel(String? topic) {
    final key = (topic ?? '').trim();
    return topicLabels[key] ?? topicLabels['general']!;
  }

  static bool isClosed(String? status) {
    return (status ?? '').trim().toLowerCase() == 'closed';
  }

  static String statusLabel(String? status) {
    return isClosed(status) ? 'Kapali' : 'Acik';
  }

  static String inboxRoleLabel({required bool isBusinessOwner}) {
    return isBusinessOwner ? 'Kurumsal gelen kutusu' : 'Bireysel mesajlar';
  }

  static String emptyInboxTitle({required bool isBusinessOwner}) {
    return isBusinessOwner ? 'Henuz musteri mesaji yok' : 'Henuz mesajiniz yok';
  }

  static String emptyInboxText({required bool isBusinessOwner}) {
    return isBusinessOwner
        ? 'Kesif, profil ve randevu akislarindan gelen bireysel kullanici mesajlari burada gorunur.'
        : 'Kesfet sayfasindan bir isletme secip ilk mesajinizi gonderebilirsiniz.';
  }

  static String threadContextTitle({required bool isBusinessOwner}) {
    return isBusinessOwner ? 'Bireysel kullanici gorusmesi' : 'Isletme gorusmesi';
  }

  static String threadContextText({required bool isBusinessOwner}) {
    return isBusinessOwner
        ? 'Yanitlariniz kurumsal hesabiniz adina bireysel kullaniciya iletilir.'
        : 'Yanitlariniz bireysel hesabiniz uzerinden isletmeye iletilir.';
  }

  static String inputHint({required bool isBusinessOwner}) {
    return isBusinessOwner
        ? 'Bireysel kullaniciya yanit yaz...'
        : 'Isletmeye mesaj yaz...';
  }

  static bool threadUnread({
    required bool isBusinessOwner,
    required bool unreadForCustomer,
    required bool unreadForBusiness,
  }) {
    return isBusinessOwner ? unreadForBusiness : unreadForCustomer;
  }

  static String closedThreadNotice({required bool isBusinessOwner}) {
    return isBusinessOwner
        ? 'Bu gorusme kapali. Yeniden acarak yanit verebilirsiniz.'
        : 'Bu gorusme isletme tarafindan kapatilmis. Yeni yanit icin isletmenin yeniden acmasi gerekir.';
  }

  static String readReceipt({
    required bool isBusinessOwner,
    required bool readByCustomer,
    required bool readByBusiness,
  }) {
    final seen = isBusinessOwner ? readByCustomer : readByBusiness;
    return seen ? 'Goruldu' : 'Gonderildi';
  }
}
