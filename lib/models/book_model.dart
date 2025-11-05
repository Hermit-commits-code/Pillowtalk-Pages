// lib/models/book_model.dart

// Represents a book from a search result (e.g., Google Books)
class RomanceBook {
  final String id;
  final String isbn;
  final String title;
  final List<String> authors;
  final String? imageUrl;
  final String? description;
  final String? publishedDate;
  final int? pageCount;

  const RomanceBook({
    required this.id,
    required this.isbn,
    required this.title,
    required this.authors,
    this.imageUrl,
    this.description,
    this.publishedDate,
    this.pageCount,
  });

  // This factory is used to parse data from Google Books API
  factory RomanceBook.fromGoogleBooks(Map<String, dynamic> item) {
    final volumeInfo = item['volumeInfo'] as Map<String, dynamic>? ?? {};
    final industryIdentifiers =
        volumeInfo['industryIdentifiers'] as List<dynamic>? ?? [];
    String isbn = '';
    for (final identifier in industryIdentifiers) {
      if (identifier['type'] == 'ISBN_13' || identifier['type'] == 'ISBN_10') {
        isbn = identifier['identifier'] as String;
        break;
      }
    }
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>? ?? {};
    String? imageUrl =
        imageLinks['extraLarge'] as String? ??
        imageLinks['large'] as String? ??
        imageLinks['medium'] as String? ??
        imageLinks['thumbnail'] as String?;
    if (imageUrl != null && imageUrl.startsWith('http:')) {
      imageUrl = imageUrl.replaceFirst('http:', 'https:');
    }

    return RomanceBook(
      id: item['id'] as String,
      isbn: isbn,
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      authors: List<String>.from(volumeInfo['authors'] ?? ['Unknown Author']),
      imageUrl: imageUrl,
      description: volumeInfo['description'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
    );
  }
}
