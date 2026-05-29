import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/admin/domain/admin_moderation_filter_policy.dart';

void main() {
  group('AdminModerationFilterPolicy', () {
    test('matches all rows when query and status are empty', () {
      expect(
        AdminModerationFilterPolicy.matches(
          id: 'claim-1',
          data: const {'status': 'pending', 'businessName': 'Fix Barber'},
          query: '',
          statusFilter: 'all',
        ),
        isTrue,
      );
    });

    test('filters by status or reviewStatus', () {
      expect(
        AdminModerationFilterPolicy.matches(
          id: 'report-1',
          data: const {'reviewStatus': 'needs_review'},
          query: '',
          statusFilter: 'needs_review',
        ),
        isTrue,
      );
      expect(
        AdminModerationFilterPolicy.matches(
          id: 'report-1',
          data: const {'status': 'resolved'},
          query: '',
          statusFilter: 'open',
        ),
        isFalse,
      );
    });

    test('searches document id and values case-insensitively', () {
      expect(
        AdminModerationFilterPolicy.matches(
          id: 'campaign-42',
          data: const {'reason': 'Spam campaign'},
          query: 'SPAM',
          statusFilter: 'all',
        ),
        isTrue,
      );
      expect(
        AdminModerationFilterPolicy.matches(
          id: 'campaign-42',
          data: const {'reason': 'Spam campaign'},
          query: 'missing',
          statusFilter: 'all',
        ),
        isFalse,
      );
    });
  });
}
