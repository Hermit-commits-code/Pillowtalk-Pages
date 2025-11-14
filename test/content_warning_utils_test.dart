import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/services/content_warning_utils.dart';

void main() {
  group('findWarningOverlap', () {
    test('returns empty list when no book warnings', () {
      final result = findWarningOverlap(null, ['Violence']);
      expect(result, isEmpty);
    });

    test('returns empty list when no user stops', () {
      final result = findWarningOverlap(['Violence'], null);
      expect(result, isEmpty);
    });

    test('returns empty list when no overlaps', () {
      final result = findWarningOverlap(['Romance'], ['Violence']);
      expect(result, isEmpty);
    });

    test('finds exact case-insensitive matches', () {
      final result = findWarningOverlap(
        ['Violence', 'Romance'],
        ['violence', 'CHEATING'],
      );
      expect(result, equals(['Violence']));
    });

    test('ignores whitespace differences', () {
      final result = findWarningOverlap(
        [' Violence ', 'Romance'],
        ['violence', 'romance '],
      );
      expect(result, equals([' Violence ', 'Romance']));
    });

    test('excludes ignored warnings', () {
      final result = findWarningOverlap(
        ['Violence', 'Cheating', 'Romance'],
        ['violence', 'cheating', 'romance'],
        ['violence', 'romance'], // ignored
      );
      expect(result, equals(['Cheating']));
    });

    test('handles empty ignored list', () {
      final result = findWarningOverlap(
        ['Violence'],
        ['violence'],
        [], // empty ignored
      );
      expect(result, equals(['Violence']));
    });

    test('handles null ignored list', () {
      final result = findWarningOverlap(
        ['Violence'],
        ['violence'],
        null, // null ignored
      );
      expect(result, equals(['Violence']));
    });

    test('complex real-world scenario', () {
      final bookWarnings = [
        'Sexual Content',
        'Violence',
        'Non-Consensual',
        'Cheating',
      ];
      final userStops = ['violence', 'non-consensual', 'abuse'];
      final ignored = ['violence']; // user decided to tolerate violence

      final result = findWarningOverlap(bookWarnings, userStops, ignored);
      expect(result, equals(['Non-Consensual']));
    });
  });
}
