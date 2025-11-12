import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class CuratedScreen extends StatefulWidget {
  const CuratedScreen({Key? key}) : super(key: key);

  @override
  State<CuratedScreen> createState() => _CuratedScreenState();
}

class _CuratedScreenState extends State<CuratedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadProStatus();
  }

  Future<void> _loadProStatus() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        setState(() => _isPro = false);
        return;
      }
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? {};
      setState(() => _isPro = (claims['pro'] == true));
    } catch (e) {
      // If anything fails, treat as not pro.
      setState(() => _isPro = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // If the user is not pro, show an upgrade banner so they know some
            // collections may be locked behind Pro.
            if (!_isPro) _buildUpgradeBanner(context),
            // Featured collection (Editor's Picks)
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('collections')
                  .doc('editors_picks')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildAuthErrorWidget(context, snapshot.error);
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final collection =
                    snapshot.data!.data() as Map<String, dynamic>;
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            _buildCollectionsGrid(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Some collections are Pro-only',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('Upgrade to Pro to unlock exclusive curated lists.'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                // Developer convenience: refresh the user's ID token and reload
                // pro status so that a recently-granted custom claim becomes active.
                final user = AuthService.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not signed in')),
                  );
                  return;
                }
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshing privileges...')),
                  );
                  // Force refresh of ID token to pick up custom claims set by admin.
                  await user.getIdTokenResult(true);
                  await _loadProStatus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privileges refreshed.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to refresh token: $e')),
                  );
                }
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
        if (snapshot.hasError) {
          return _buildAuthErrorWidget(context, snapshot.error);
        }
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
            final visibility = (collection['visibility'] ?? 'public') as String;
            final locked = (visibility == 'pro') && !_isPro;

            return _CollectionCard(
              title: title,
              description: description,
              bookCount: bookIds.length,
              collectionId: collectionId,
              bookIds: bookIds,
              locked: locked,
            );
          },
        );
      },
    );
  }

  Widget _buildAuthErrorWidget(BuildContext context, Object? error) {
    final message = (error != null)
        ? error.toString()
        : 'Unable to load collections.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collections unavailable',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'The app does not have permission to read curated collections.\n$message',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  // Try a quick anonymous sign-in to recover if the app is running locally.
                  try {
                    final cred = await AuthService.instance.signInAnonymously();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Signed in as ${cred.user?.uid}')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign-in failed: $e')),
                    );
                  }
                },
                child: const Text('Sign in (anonymous)'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  // Open docs or show guidance — keep simple for now
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'If this is unexpected, check Firestore rules.',
                      ),
                    ),
                  );
                },
                child: const Text('Help'),
              ),
            ],
          ),
        ],
      ),
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
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Book was deleted from database; return empty widget (no placeholder)
          return const SizedBox.shrink();
        }

        final bookData = snapshot.data!.data();
        if (bookData == null) {
          // Book doc exists but is empty (shouldn't happen, but safe guard)
          return const SizedBox.shrink();
        }

        final book = bookData as Map<String, dynamic>;
        final title = book['title'] ?? 'Unknown';
        final imageUrl = book['imageUrl'];

        // Constrain the card to the carousel height so the internal
        // Column can use Expanded/Flexible for the title area and never
        // overflow. This is more robust than relying on exact pixel math.
        return GestureDetector(
          onTap: () => context.push('/book/$bookId'),
          child: SizedBox(
            width: 140,
            height: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image portion takes a fixed portion of the card height.
                Container(
                  width: 140,
                  height: 160,
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
                      ? const Center(child: Icon(Icons.book))
                      : null,
                ),
                const SizedBox(height: 8),

                // Title area is flexible and will ellipsize if it can't fit.
                Expanded(
                  child: SizedBox(
                    width: 140,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
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
  final bool locked;

  const _CollectionCard({
    required this.title,
    required this.description,
    required this.bookCount,
    required this.collectionId,
    required this.bookIds,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked
          ? () {
              // Show upgrade prompt for locked collections
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This collection is Pro-only. Upgrade to access.',
                  ),
                ),
              );
            }
          : () => context.push(
              '/curated-collection/$collectionId',
              extra: {'title': title, 'bookIds': bookIds},
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Locked overlay for Pro-only collections
            if (locked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock, color: Colors.white, size: 36),
                        SizedBox(height: 8),
                        Text(
                          'Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
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
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }

        final bookData = snapshot.data!.data();
        if (bookData == null) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }

        final book = bookData as Map<String, dynamic>;
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
