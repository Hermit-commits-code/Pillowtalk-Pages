import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/constants/tropes_categorized.dart';

void main() {
  test('inspect tropes', () {
    // ignore: avoid_print
    print('Total tropes: ${romanceTropesCategorized.length}');
    for (
      var i = 0;
      i <
          (romanceTropesCategorized.length < 50
              ? romanceTropesCategorized.length
              : 50);
      i++
    ) {
      // ignore: avoid_print
      print('[$i] ${romanceTropesCategorized[i]}');
    }
    expect(romanceTropesCategorized.contains('Friends to Lovers'), isTrue);
  });
}
