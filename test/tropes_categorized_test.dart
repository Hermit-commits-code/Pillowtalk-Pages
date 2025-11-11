import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/constants/tropes_categorized.dart';

void main() {
  test('no duplicate tropes across categories', () {
    final all = romanceTropesCategorized;
    final unique = all.toSet();
    expect(
      all.length,
      equals(unique.length),
      reason: 'There should be no duplicated trope strings across categories',
    );
  });

  test('contains a few expected tropes', () {
    expect(romanceTropesCategorized.contains('Friends to Lovers'), isTrue);
    expect(romanceTropesCategorized.contains('Arranged Marriage'), isTrue);
    expect(romanceTropesCategorized.contains('Amnesia'), isTrue);
  });
}
