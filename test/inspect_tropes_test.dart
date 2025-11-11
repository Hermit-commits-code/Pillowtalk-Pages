import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/constants/tropes_categorized.dart';

void main() {
  test('inspect tropes', () {
    print('Total tropes: ${romanceTropesCategorized.length}');
    for (
      var i = 0;
      i <
          (romanceTropesCategorized.length < 50
              ? romanceTropesCategorized.length
              : 50);
      i++
    ) {
      print('[$i] ${romanceTropesCategorized[i]}');
    }
    expect(romanceTropesCategorized.contains('Friends to Lovers'), isTrue);
  });
}
