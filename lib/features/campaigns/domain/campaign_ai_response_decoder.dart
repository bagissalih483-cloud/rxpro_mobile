import 'dart:convert';

class CampaignAiResponseDecoder {
  const CampaignAiResponseDecoder._();

  static Map<String, dynamic> decodeBodyBytes(List<int> bodyBytes) {
    if (bodyBytes.isEmpty) return <String, dynamic>{};

    final text = utf8.decode(bodyBytes).trim();
    if (text.isEmpty) return <String, dynamic>{};

    final raw = jsonDecode(text);
    if (raw is! Map) return <String, dynamic>{};

    return Map<String, dynamic>.from(raw);
  }
}
