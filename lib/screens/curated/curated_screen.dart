import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class CuratedScreen extends StatefulWidget {
  const CuratedScreen({Key? key}) : super(key: key);

  @override
  State<CuratedScreen> createState() => _CuratedScreenState();
}

class _CuratedScreenState extends State<CuratedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Curated Collections',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover handpicked romance across all your favorite subgenres',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Featured collection (Editor's Picks)
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('collections')
                .doc('editors_picks')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              final collection = snapshot.data!.data() as Map<String, dynamic>;
              final title = collection['title'] ?? '';
              final bookIds = List<String>.from(collection['bookIds'] ?? []);

              if (bookIds.isEmpty) {
                return const SizedBox.shrink();
              }

              return _buildFeaturedCarousel(context, title, bookIds);
            },
          ),
          const SizedBox(height: 24),
          // Collections grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Browse by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCollectionsGrid(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeaturedCarousel(
    BuildContext context,
    String title,
    List<String> bookIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: bookIds.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _BookCard(bookId: bookIds[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('collections')
          .where('isFeatured', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No collections found'));
        }

        final collections = snapshot.data!.docs;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection =
                collections[index].data() as Map<String, dynamic>;
            final collectionId = collections[index].id;
            final title = collection['title'] ?? '';
            final description = collection['description'] ?? '';
            final bookIds = List<String>.from(collection['bookIds'] ?? []);

            return _CollectionCard(
              title: title,
              description: description,
              bookCount: bookIds.length,
              collectionId: collectionId,
              bookIds: bookIds,
            );
          },
        );
      },
    );
  }
}

/// Card displaying a single book thumbnail
class _BookCard extends StatelessWidget {
  final String bookId;

  const _BookCard({required this.bookId});

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
            width: 140,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        final book = snapshot.data!.data() as Map<String, dynamic>;
        final title = book['title'] ?? 'Unknown';
        final imageUrl = book['imageUrl'];

        return GestureDetector(
          onTap: () => context.push('/book/$bookId'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                height: 180,
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
                    ? const Center(
                        child: Icon(Icons.book),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 140,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Card for a collection with a preview grid
class _CollectionCard extends StatelessWidget {
  final String title;
  final String description;
  final int bookCount;
  final String collectionId;
  final List<String> bookIds;

  const _CollectionCard({
    required this.title,
    required this.description,
    required this.bookCount,
    required this.collectionId,
    required this.bookIds,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/curated-collection/$collectionId',
        extra: {
          'title': title,
          'bookIds': bookIds,
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Preview grid of first 4 books
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: bookIds.take(4).length,
                itemBuilder: (context, index) {
                  return _BookPreviewThumbnail(bookId: bookIds[index]);
                },
              ),
            ),
            // Overlay with title and count
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$bookCount books',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small book thumbnail for collection preview
class _BookPreviewThumbnail extends StatelessWidget {
  final String bookId;

  const _BookPreviewThumbnail({required this.bookId});

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
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }

        final book = snapshot.data!.data() as Map<String, dynamic>;
        final imageUrl = book['imageUrl'];

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        );
      },
    );
  }
}
