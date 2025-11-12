import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class CuratedCollectionScreen extends StatelessWidget {
  final String collectionId;
  final String title;
  final List<String> bookIds;

  const CuratedCollectionScreen({
    Key? key,
    required this.collectionId,
    required this.title,
    required this.bookIds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), elevation: 0),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: bookIds.length,
        itemBuilder: (context, index) {
          return _BookGridItem(bookId: bookIds[index]);
        },
      ),
    );
  }
}

class _BookGridItem extends StatelessWidget {
  final String bookId;

  const _BookGridItem({required this.bookId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .doc(bookId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        final book = snapshot.data!.data() as Map<String, dynamic>;
        final title = book['title'] ?? 'Unknown';
        final authors =
            (book['authors'] as List<dynamic>?)?.cast<String>() ?? [];
        final imageUrl = book['imageUrl'];

        return GestureDetector(
          onTap: () => context.push('/book/$bookId'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    image: imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl == null
                      ? const Center(child: Icon(Icons.book, size: 40))
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                authors.isNotEmpty ? authors[0] : 'Unknown Author',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }
}
