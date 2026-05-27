import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/campaigns/domain/campaign_ai_response_decoder.dart';

void main() {
  group('CampaignAiResponseDecoder', () {
    test('decodes Turkish UTF-8 campaign text from response bytes', () {
      final bytes = utf8.encode(
        '{"title":"Mayıs fırsatı","body":"Sağlık ve güzellik kampanyası"}',
      );

      final decoded = CampaignAiResponseDecoder.decodeBodyBytes(bytes);

      expect(decoded['title'], 'Mayıs fırsatı');
      expect(decoded['body'], 'Sağlık ve güzellik kampanyası');
    });

    test('returns empty map for empty response bodies', () {
      expect(CampaignAiResponseDecoder.decodeBodyBytes(const []), isEmpty);
    });
  });
}
