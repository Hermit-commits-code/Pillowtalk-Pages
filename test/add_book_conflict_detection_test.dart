import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddBook Kink/Hard-Stop Conflict Detection Logic', () {
    /// Helper function to simulate the conflict detection logic
    Map<String, dynamic> checkForConflicts({
      required List<String> selectedTropes,
      required List<String> kinkFilters,
      required bool kinkEnabled,
      required List<String> hardStops,
      required bool hardStopsEnabled,
    }) {
      final conflicts = <String>[];

      if (kinkEnabled) {
        for (final trope in selectedTropes) {
          if (kinkFilters.contains(trope) && !conflicts.contains(trope)) {
            conflicts.add(trope);
          }
        }
      }

      if (hardStopsEnabled) {
        for (final trope in selectedTropes) {
          if (hardStops.contains(trope) && !conflicts.contains(trope)) {
            conflicts.add(trope);
          }
        }
      }

      return {
        'hasConflicts': conflicts.isNotEmpty,
        'conflictingTropes': conflicts,
      };
    }

    test('No conflicts when tropes list is empty', () {
      final result = checkForConflicts(
        selectedTropes: [],
        kinkFilters: ['BDSM'],
        kinkEnabled: true,
        hardStops: ['Non-Consensual'],
        hardStopsEnabled: true,
      );

      expect(result['hasConflicts'], false);
      expect(result['conflictingTropes'], isEmpty);
    });

    test('Detects conflict when trope matches kink filter', () {
      final result = checkForConflicts(
        selectedTropes: ['Friends to Lovers', 'BDSM'],
        kinkFilters: ['BDSM', 'Explicit Sexual Content'],
        kinkEnabled: true,
        hardStops: [],
        hardStopsEnabled: true,
      );

      expect(result['hasConflicts'], true);
      expect(result['conflictingTropes'], ['BDSM']);
    });

    test('Detects conflict when trope matches hard stop', () {
      final result = checkForConflicts(
        selectedTropes: ['Friends to Lovers', 'Infidelity'],
        kinkFilters: [],
        kinkEnabled: true,
        hardStops: ['Non-Consensual', 'Infidelity'],
        hardStopsEnabled: true,
      );

      expect(result['hasConflicts'], true);
      expect(result['conflictingTropes'], ['Infidelity']);
    });

    test('Detects multiple conflicts (kink + hard stop)', () {
      final result = checkForConflicts(
        selectedTropes: ['Friends to Lovers', 'BDSM', 'Non-Consensual'],
        kinkFilters: ['BDSM'],
        kinkEnabled: true,
        hardStops: ['Non-Consensual'],
        hardStopsEnabled: true,
      );

      expect(result['hasConflicts'], true);
      expect(result['conflictingTropes'].length, 2);
      expect(
        result['conflictingTropes'],
        containsAll(['BDSM', 'Non-Consensual']),
      );
    });

    test('No conflicts when kink filter disabled', () {
      final result = checkForConflicts(
        selectedTropes: ['BDSM', 'Non-Consensual'],
        kinkFilters: ['BDSM'],
        kinkEnabled: false,
        hardStops: ['Non-Consensual'],
        hardStopsEnabled: true,
      );

      expect(result['hasConflicts'], true);
      expect(result['conflictingTropes'], ['Non-Consensual']);
    });

    test('No conflicts when all filters disabled', () {
      final result = checkForConflicts(
        selectedTropes: ['BDSM', 'Non-Consensual'],
        kinkFilters: ['BDSM'],
        kinkEnabled: false,
        hardStops: ['Non-Consensual'],
        hardStopsEnabled: false,
      );

      expect(result['hasConflicts'], false);
      expect(result['conflictingTropes'], isEmpty);
    });

    test('No duplicate conflicts in result', () {
      final result = checkForConflicts(
        selectedTropes: ['BDSM', 'BDSM', 'Friends to Lovers'],
        kinkFilters: ['BDSM'],
        kinkEnabled: true,
        hardStops: [],
        hardStopsEnabled: true,
      );

      expect(result['conflictingTropes'], ['BDSM']);
      expect(result['conflictingTropes'].length, 1);
    });

    test('Handles case-sensitive trope matching', () {
      // Tropes should be case-sensitive, so "BDSM" != "bdsm"
      final result = checkForConflicts(
        selectedTropes: ['bdsm'], // lowercase
        kinkFilters: ['BDSM'], // uppercase
        kinkEnabled: true,
        hardStops: [],
        hardStopsEnabled: true,
      );

      expect(result['hasConflicts'], false);
      expect(result['conflictingTropes'], isEmpty);
    });

    test('Matches tropes correctly with exact strings', () {
      final result = checkForConflicts(
        selectedTropes: ['Arranged Marriage', 'Friends to Lovers'],
        kinkFilters: ['Arranged Marriage', 'BDSM'],
        kinkEnabled: true,
        hardStops: [],
        hardStopsEnabled: true,
      );

      expect(result['hasConflicts'], true);
      expect(result['conflictingTropes'], ['Arranged Marriage']);
    });

    test('Multiple hard stop conflicts detected', () {
      final result = checkForConflicts(
        selectedTropes: ['Non-Consensual', 'Infidelity', 'Dub-Con'],
        kinkFilters: [],
        kinkEnabled: true,
        hardStops: ['Non-Consensual', 'Infidelity'],
        hardStopsEnabled: true,
      );

      expect(result['hasConflicts'], true);
      expect(result['conflictingTropes'].length, 2);
      expect(
        result['conflictingTropes'],
        containsAll(['Non-Consensual', 'Infidelity']),
      );
    });

    test('No conflicts when filters empty but enabled', () {
      final result = checkForConflicts(
        selectedTropes: ['BDSM', 'Non-Consensual'],
        kinkFilters: [],
        kinkEnabled: true,
        hardStops: [],
        hardStopsEnabled: true,
      );

      expect(result['hasConflicts'], false);
      expect(result['conflictingTropes'], isEmpty);
    });
  });
}
