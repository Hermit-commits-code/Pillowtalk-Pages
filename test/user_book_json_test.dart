import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/models/user_book.dart';

void main() {
  test('UserBook toJson/fromJson roundtrip retains fields', () {
    final now = DateTime.now();
    final ub = UserBook(
      id: 'ub1',
      userId: 'user1',
      bookId: 'b1',
      status: ReadingStatus.wantToRead,
      dateAdded: now,
      userSelectedTropes: ['Grumpy Sunshine'],
      userContentWarnings: ['Infidelity/Cheating'],
      userNotes: 'Notes',
      genre: 'Contemporary',
      subgenres: ['Romantic Comedy'],
      cachedTopWarnings: ['Infidelity/Cheating'],
      cachedTropes: ['Grumpy Sunshine'],
      ignoreFilters: false,
    );

    final json = ub.toJson();
    final parsed = UserBook.fromJson(json);

    expect(parsed.id, ub.id);
    expect(parsed.userId, ub.userId);
    expect(parsed.bookId, ub.bookId);
    expect(parsed.status, ub.status);
    expect(parsed.userSelectedTropes, ub.userSelectedTropes);
    expect(parsed.userContentWarnings, ub.userContentWarnings);
    expect(parsed.userNotes, ub.userNotes);
    expect(parsed.genre, ub.genre);
    expect(parsed.subgenres, ub.subgenres);
    expect(parsed.cachedTopWarnings, ub.cachedTopWarnings);
    expect(parsed.cachedTropes, ub.cachedTropes);
    expect(parsed.ignoreFilters, ub.ignoreFilters);
  });
}
