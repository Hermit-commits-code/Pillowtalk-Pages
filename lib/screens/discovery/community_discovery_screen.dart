// lib/screens/discovery/community_discovery_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/community_book.dart';
import '../../models/user_book.dart';
import '../../services/community_book_service.dart';
import '../../services/user_library_service.dart';
import '../../services/auth_service.dart';
import '../../services/feature_gating_service.dart';
import '../../services/pro_status_service.dart';
import '../../widgets/loading_spinner.dart';

/// Community Discovery Screen - Find new books from the community database
/// Perfect for mood-based discovery like "I'm in the mood for werewolf books"
class CommunityDiscoveryScreen extends StatefulWidget {
  const CommunityDiscoveryScreen({super.key});

  @override
  State<CommunityDiscoveryScreen> createState() =>
      _CommunityDiscoveryScreenState();
}

class _CommunityDiscoveryScreenState extends State<CommunityDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final _communityBookService = CommunityBookService.instance;
  final _userLibraryService = UserLibraryService();
  final _proStatusService = ProStatusService();
  final _searchController = TextEditingController();

  late TabController _tabController;

  // State
  List<CommunityBook> _searchResults = [];
  List<CommunityBook> _trendingBooks = [];
  List<CommunityBook> _recommendedBooks = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isPro = false;
  String? _error;

  // Quick mood searches - expanded for Pro users
  List<String> get _moodTags {
    final baseTags = [
      'Werewolf Romance',
      'Enemies to Lovers',
      'Spicy Fantasy',
      'Vampire Romance',
      'Grumpy Sunshine',
      'Age Gap',
      'Fake Dating',
      'Historical Romance',
    ];

    if (_isPro) {
      return [
        ...baseTags,
        'Dark Romance',
        'Reverse Harem',
        'Omegaverse',
        'Forced Proximity',
        'Second Chance',
        'Medical Romance',
      ];
    }

    return baseTags;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Load Pro status
      final isPro = await _proStatusService.isPro();

      // Load trending and recommended books
      final trending = await _communityBookService.getTrendingBooks();
      final recommended = await _communityBookService.getRandomDiscovery();

      setState(() {
        _isPro = isPro;
        _trendingBooks = trending;
        _recommendedBooks = recommended;
      });
    } catch (e) {
      setState(() => _error = 'Failed to load discovery data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      final results = await _communityBookService.moodSearch(query);
      setState(() => _searchResults = results);
    } catch (e) {
      setState(() => _error = 'Search failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _quickMoodSearch(String mood) async {
    _searchController.text = mood;
    await _searchBooks();
  }

  Future<void> _addToLibrary(CommunityBook book) async {
    try {
      setState(() => _isLoading = true);

      final user = AuthService.instance.currentUser;
      if (user == null) throw Exception('Please log in first');

      // Check Pro limits
      final canAdd = await FeatureGatingService().checkBookLimitAndPrompt(
        context,
      );
      if (!canAdd) {
        return;
      }

      // Convert community book to user book format
      final userBookData = _communityBookService.toUserBookData(book, user.uid);

      // Create a temporary UserBook to add
      final userBook = UserBook.fromJson({
        ...userBookData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      });

      await _userLibraryService.addBook(userBook);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${book.title}" to your library!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => context.go('/library'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Books'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Search'),
            Tab(text: 'Trending'),
            Tab(text: 'For You'),
            Tab(text: 'My Books'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(theme),
          _buildTrendingTab(theme),
          _buildRecommendedTab(theme),
          _buildMyBooksTab(theme),
        ],
      ),
    );
  }

  Widget _buildSearchTab(ThemeData theme) {
    return Column(
      children: [
        // Search input
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'What mood are you in?',
                        hintText:
                            'Try "spicy werewolf romance" or "enemies to lovers"',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _searchBooks(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _searchBooks,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quick mood tags
              Text(
                'Quick Moods',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ..._moodTags.map(
                        (mood) => ActionChip(
                          label: Text(
                            mood,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _quickMoodSearch(mood),
                          backgroundColor: theme.colorScheme.primaryContainer,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                      if (!_isPro)
                        ActionChip(
                          label: const Text(
                            '+ More with Pro',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: () => context.push('/pro-club'),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          avatar: const Icon(Icons.star, size: 14),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search results
        Expanded(child: _buildSearchResults(theme)),
      ],
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: LoadingSpinner());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Ready to discover new books?',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Search by mood, trope, or try one of the quick mood tags above.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.7 * 255).round(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No books found for that mood. Try a different search!'),
      );
    }

    return _buildBookGrid(_searchResults);
  }

  Widget _buildTrendingTab(ThemeData theme) {
    if (_isLoading && _trendingBooks.isEmpty) {
      return const Center(child: LoadingSpinner());
    }

    if (_trendingBooks.isEmpty) {
      return const Center(child: Text('No trending books available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trending This Week',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Books that the community is buzzing about',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.7 * 255).round(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBookGrid(_trendingBooks)),
      ],
    );
  }

  Widget _buildRecommendedTab(ThemeData theme) {
    if (_isLoading && _recommendedBooks.isEmpty) {
      return const Center(child: LoadingSpinner());
    }

    if (_recommendedBooks.isEmpty) {
      return const Center(child: Text('No recommendations available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isPro ? 'Curated For You' : 'Discover Books',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isPro
                    ? 'Personalized recommendations based on your reading history'
                    : 'Handpicked selection from our community library',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.7 * 255).round(),
                  ),
                ),
              ),
              if (!_isPro) ...[
                const SizedBox(height: 12),
                Card(
                  color: theme.colorScheme.secondaryContainer.withAlpha(
                    (0.3 * 255).round(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Upgrade to Pro for personalized recommendations',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/pro-club'),
                          child: const Text('Upgrade'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _buildBookGrid(_recommendedBooks)),
      ],
    );
  }

  Widget _buildMyBooksTab(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Search Your Personal Library',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Advanced search through the books you\'ve already added to your personal collection.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
            label: const Text('Open Personal Library Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookGrid(List<CommunityBook> books) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(CommunityBook book) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Book cover
          Expanded(
            flex: 3,
            child: book.imageUrl != null
                ? Image.network(
                    book.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.book, size: 48),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.book, size: 48),
                  ),
          ),

          // Book details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.authors.join(', '),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Social proof
                  if (book.socialProofText.isNotEmpty) ...[
                    Text(
                      book.socialProofText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Add to library button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _addToLibrary(book),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Add to Library'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
