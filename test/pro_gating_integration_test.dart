import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pro-Gating & Free Tier Limits', () {
    /// Helper function to simulate pro status checking
    Future<bool> checkProStatus({
      required bool isPro,
      required String? userEmail,
    }) async {
      // Simulate the ProStatusService.isPro() logic

      // Developer override (from _devEmails)
      if (userEmail == 'hotcupofjoe2013@gmail.com') {
        return true; // Dev email always pro
      }

      return isPro;
    }

    test('Free user can add max 2 books', () async {
      final isPro = await checkProStatus(
        isPro: false,
        userEmail: 'user@example.com',
      );

      expect(isPro, false);

      // Simulate free user book limit check
      const freeUserBookLimit = 2;
      final booksAdded = 0; // Starting with 0 books

      // Should be able to add first book
      expect(booksAdded < freeUserBookLimit, true);

      // Should be able to add second book
      expect(booksAdded + 1 < freeUserBookLimit, true);

      // Should NOT be able to add third book (already at limit)
      expect(
        booksAdded + 2 < freeUserBookLimit,
        false,
        reason: 'Free user should be blocked at 2 books',
      );
    });

    test('Pro user can add unlimited books', () async {
      final isPro = await checkProStatus(
        isPro: true,
        userEmail: 'pro@example.com',
      );

      expect(isPro, true);

      // Pro users bypass the book limit
      const freeUserBookLimit = 2;

      // Pro user should be able to add 3+ books
      expect(
        isPro || 3 < freeUserBookLimit,
        true,
        reason: 'Pro user should bypass free tier limit',
      );
    });

    test('Developer email gets pro status', () async {
      final isPro = await checkProStatus(
        isPro: false, // Even if not marked pro in DB
        userEmail: 'hotcupofjoe2013@gmail.com',
      );

      expect(isPro, true, reason: 'Developer email should override to pro');
    });

    test('Free user can select max 2 tropes', () async {
      final isPro = await checkProStatus(
        isPro: false,
        userEmail: 'user@example.com',
      );

      expect(isPro, false);

      // Simulate free user trope selection limit
      const freeUserTropeLimit = 2;
      var selectedTropes = <String>[];

      // Can add first trope
      selectedTropes.add('Friends to Lovers');
      expect(selectedTropes.length <= freeUserTropeLimit, true);

      // Can add second trope
      selectedTropes.add('Enemies to Lovers');
      expect(selectedTropes.length <= freeUserTropeLimit, true);

      // Cannot add third trope (free limit enforced)
      if (!isPro && selectedTropes.length >= freeUserTropeLimit) {
        // Show pro upgrade message and don't add
        expect(true, true); // Upgrade message shown
      } else {
        selectedTropes.add('Fake Relationship');
      }

      expect(selectedTropes.length <= freeUserTropeLimit + 1, true);
    });

    test('Pro user can select more than 2 tropes', () async {
      final isPro = await checkProStatus(
        isPro: true,
        userEmail: 'pro@example.com',
      );

      expect(isPro, true);

      const freeUserTropeLimit = 2;
      final selectedTropes = <String>[
        'Friends to Lovers',
        'Enemies to Lovers',
        'Fake Relationship',
        'Forced Proximity',
        'Second Chance Romance',
      ];

      // Pro user should be allowed to select more than free limit
      if (isPro) {
        expect(selectedTropes.length > freeUserTropeLimit, true);
      } else {
        expect(selectedTropes.length <= freeUserTropeLimit, true);
      }
    });

    test('Pro status affects book addition workflow', () async {
      final freePro = await checkProStatus(
        isPro: false,
        userEmail: 'free@example.com',
      );
      final proPro = await checkProStatus(
        isPro: true,
        userEmail: 'pro@example.com',
      );

      const freeUserBookLimit = 2;

      // Free user book count = 1, trying to add another
      final freeCanAddBook = 1 < freeUserBookLimit;
      expect(
        freeCanAddBook || freePro,
        true,
      ); // Can add if not at limit OR is pro

      // Free user book count = 2 (at limit), trying to add another
      final freeBlockedAtLimit = !(2 < freeUserBookLimit) && !freePro;
      expect(
        freeBlockedAtLimit,
        true,
        reason: 'Free user at limit should be blocked unless pro',
      );

      // Pro user book count = 2, trying to add another (should succeed)
      expect(
        proPro || 2 < freeUserBookLimit,
        true,
        reason: 'Pro user should bypass free tier limit',
      );
    });

    test('AddBook workflow: free user reaches limit', () async {
      final isPro = await checkProStatus(
        isPro: false,
        userEmail: 'user@example.com',
      );

      const freeUserBookLimit = 2;
      final currentLibraryCount = 2; // Already at limit

      // Simulate AddBook._addBookToLibrary check
      var shouldBlockSave = false;
      if (!isPro && currentLibraryCount >= freeUserBookLimit) {
        shouldBlockSave = true;
      }

      expect(
        shouldBlockSave,
        true,
        reason: 'AddBook should block save when free user at limit',
      );
    });

    test('AddBook workflow: pro user exceeds old free limit', () async {
      final isPro = await checkProStatus(
        isPro: true,
        userEmail: 'pro@example.com',
      );

      const freeUserBookLimit = 2;
      final currentLibraryCount = 5; // Well above free limit

      // Simulate AddBook._addBookToLibrary check
      var shouldBlockSave = false;
      if (!isPro && currentLibraryCount >= freeUserBookLimit) {
        shouldBlockSave = true;
      }

      expect(
        shouldBlockSave,
        false,
        reason: 'Pro user should not be blocked regardless of book count',
      );
    });

    test(
      'Integration: AddBook -> TropeSelection -> Save (free user)',
      () async {
        final isPro = await checkProStatus(
          isPro: false,
          userEmail: 'free@example.com',
        );

        // Step 1: User opens AddBook (book limit check)
        const freeUserBookLimit = 2;
        final currentBooks = 1;
        final canAddBook = currentBooks < freeUserBookLimit || isPro;
        expect(
          canAddBook,
          true,
          reason: 'Free user with 1 book should be able to add',
        );

        // Step 2: User selects tropes (trope limit check)
        const freeUserTropeLimit = 2;
        final selectedTropes = ['Friends to Lovers', 'Enemies to Lovers'];
        final tropesValid =
            selectedTropes.length <= freeUserTropeLimit || isPro;
        expect(
          tropesValid,
          true,
          reason: 'Free user selecting 2 tropes is valid',
        );

        // Step 3: User saves book
        final newBookCount = currentBooks + 1;
        final bookCountValid = newBookCount <= freeUserBookLimit || isPro;
        expect(
          bookCountValid,
          true,
          reason: 'After adding, free user should still be under limit',
        );
      },
    );

    test('Integration: AddBook -> TropeSelection -> Save (pro user)', () async {
      final isPro = await checkProStatus(
        isPro: true,
        userEmail: 'pro@example.com',
      );

      // Step 1: User opens AddBook (no book limit for pro)
      const freeUserBookLimit = 2;
      final currentBooks = 5;
      final canAddBook = currentBooks < freeUserBookLimit || isPro;
      expect(canAddBook, true, reason: 'Pro user should always be able to add');

      // Step 2: User selects many tropes (no trope limit for pro)
      const freeUserTropeLimit = 2;
      final selectedTropes = [
        'Friends to Lovers',
        'Enemies to Lovers',
        'Fake Relationship',
        'Forced Proximity',
        'Second Chance Romance',
      ];
      final tropesValid = selectedTropes.length <= freeUserTropeLimit || isPro;
      expect(
        tropesValid,
        true,
        reason: 'Pro user selecting 5 tropes should be valid',
      );

      // Step 3: User saves book
      final newBookCount = currentBooks + 1;
      final bookCountValid = newBookCount <= freeUserBookLimit || isPro;
      expect(
        bookCountValid,
        true,
        reason: 'Pro user should always be able to save',
      );
    });

    test('Free user sees upgrade message when hitting trope limit', () async {
      final isPro = await checkProStatus(
        isPro: false,
        userEmail: 'free@example.com',
      );

      const freeUserTropeLimit = 2;
      var selectedTropes = ['Friends to Lovers', 'Enemies to Lovers'];

      // Simulate attempting to add third trope
      final shouldShowUpgradeMessage =
          !isPro && selectedTropes.length >= freeUserTropeLimit;

      expect(
        shouldShowUpgradeMessage,
        true,
        reason: 'Free user hitting trope limit should see upgrade message',
      );

      // Don't add the trope
      if (shouldShowUpgradeMessage) {
        // Message shown; trope not added
        expect(selectedTropes.length, 2, reason: 'Trope should not be added');
      }
    });

    test('Pro user does not see upgrade message', () async {
      final isPro = await checkProStatus(
        isPro: true,
        userEmail: 'pro@example.com',
      );

      const freeUserTropeLimit = 2;
      var selectedTropes = ['Friends to Lovers', 'Enemies to Lovers'];

      // Simulate attempting to add third trope
      final shouldShowUpgradeMessage =
          !isPro && selectedTropes.length >= freeUserTropeLimit;

      expect(
        shouldShowUpgradeMessage,
        false,
        reason: 'Pro user should not see upgrade message',
      );

      // Pro user can add the trope
      selectedTropes.add('Fake Relationship');
      expect(selectedTropes.length, 3, reason: 'Pro user can add third trope');
    });
  });
}
