import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/models/user_book.dart';

void main() {
  test('UserBook JSON serialization', () {
    final userBook = UserBook(
      id: '1',
      userId: 'user1',
      bookId: 'book1',
      title: 'Test Book',
      authors: ['Test Author'],
      status: ReadingStatus.reading,
    );

    final json = userBook.toJson();
    final fromJson = UserBook.fromJson(json);

    expect(fromJson.id, userBook.id);
    expect(fromJson.title, userBook.title);
  });
}
