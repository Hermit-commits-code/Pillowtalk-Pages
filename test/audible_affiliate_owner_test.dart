import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/config/admin.dart';
import 'package:spicyreads/services/audible_affiliate_service.dart';

void main() {
  group('AudibleAffiliateService - Owner-only Analytics Config', () {
    late AudibleAffiliateService service;

    setUp(() {
      service = AudibleAffiliateService();
    });

    test('admin config has sensible defaults', () {
      // Verify config exists and has sensible defaults
      expect(kRestrictAnalyticsToOwners, isA<bool>());
      expect(kOwnerAnalyticsUids, isA<List<String>>());
      expect(kOwnerAnalyticsEmails, isA<List<String>>());
    });

    test('owner emails fallback is present', () {
      // Verify fallback email is included for local testing
      final hasFallback = kOwnerAnalyticsEmails.contains(
        'hotcupofjoe2013@gmail.com',
      );
      expect(hasFallback, true);
    });

    test('can instantiate AudibleAffiliateService', () {
      // Verify service can be created without errors
      expect(service, isNotNull);
    });

    test('owner-only restrict flag is properly configured', () {
      // Document the current owner-only restriction state
      // If set to true, only owners can track analytics
      expect(
        kRestrictAnalyticsToOwners,
        isA<bool>(),
      );
      // If restricted, verify we have at least one owner identifier
      if (kRestrictAnalyticsToOwners) {
        final hasOwnerIds = kOwnerAnalyticsUids.isNotEmpty ||
            kOwnerAnalyticsEmails.isNotEmpty;
        expect(hasOwnerIds, true,
            reason:
                'Owner-only mode is enabled but no owner identifiers defined');
      }
    });

    test('setUserAnalyticsEnabled is available as public method', () {
      // Verify the method exists and is callable (doesn't throw)
      expect(
        () => service.setUserAnalyticsEnabled('test-user', true),
        returnsNormally,
      );
    });
  });
}

