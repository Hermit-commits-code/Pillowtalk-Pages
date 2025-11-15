import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/services/audible_affiliate_service.dart';

void main() {
  test('analytics preference cache and setter', () async {
    final svc = AudibleAffiliateService();
    // Use a fake user id for testing cache behavior
    const userId = 'test-user-123';

    // Seed the local cache so tests don't rely on Firestore or runtime owner config
    svc.setUserAnalyticsEnabled(userId, true);
    // Override runtime restrict flag to avoid owner-only restrictions during unit tests
    svc.setRuntimeRestrictAnalyticsFlag(false);
    // Ensure default (when explicitly seeded) returns true (enabled)
    final initial = await svc.isAnalyticsAllowedForUser(userId);
    expect(initial, isTrue);

    // Set to false and verify cache reflects change
    svc.setUserAnalyticsEnabled(userId, false);
    final afterSet = await svc.isAnalyticsAllowedForUser(userId);
    expect(afterSet, isFalse);

    // Set to true and verify cache reflects change
    svc.setUserAnalyticsEnabled(userId, true);
    final afterSetTrue = await svc.isAnalyticsAllowedForUser(userId);
    expect(afterSetTrue, isTrue);
  });
}
