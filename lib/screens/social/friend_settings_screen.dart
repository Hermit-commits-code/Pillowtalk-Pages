import 'package:flutter/material.dart';
import '../../models/friend.dart';
import '../../services/friends_service.dart';

class FriendSettingsScreen extends StatefulWidget {
  final String friendId;

  const FriendSettingsScreen({
    super.key,
    required this.friendId,
  });

  @override
  State<FriendSettingsScreen> createState() => _FriendSettingsScreenState();
}

class _FriendSettingsScreenState extends State<FriendSettingsScreen> {
  final FriendsService _friendsService = FriendsService();
  late Friend _friend;
  bool _isLoading = true;
  bool _isSaving = false;

  // Local state for toggles
  late bool _shareReadingProgress;
  late bool _shareSpiceRatings;
  late bool _shareHardStops;
  late bool _shareReviews;

  @override
  void initState() {
    super.initState();
    _loadFriend();
  }

  Future<void> _loadFriend() async {
    try {
      final friend = await _friendsService.getFriend(widget.friendId);
      if (friend != null && mounted) {
        setState(() {
          _friend = friend;
          _shareReadingProgress = friend.sharingReadingProgress;
          _shareSpiceRatings = friend.sharingSpiceRatings;
          _shareHardStops = friend.sharingHardStops;
          _shareReviews = friend.sharingReviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading friend: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      await _friendsService.updateSharingPreferences(
        widget.friendId,
        readingProgress: _shareReadingProgress,
        spiceRatings: _shareSpiceRatings,
        hardStops: _shareHardStops,
        reviews: _shareReviews,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing preferences updated!')),
      );
      setState(() => _isSaving = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _removeFriend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend?'),
        content: const Text('This friend will no longer have access to your shared data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _friendsService.removeFriend(widget.friendId);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend removed')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friend Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sharing Preferences'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Friend Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(_friend.friendId.substring(0, 2).toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Friend',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Added ${_formatDate(_friend.acceptedAt ?? _friend.createdAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sharing Settings Section
            Text(
              'What can this friend see?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Control what data you share with this friend',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // Sharing toggles
            _buildSharingToggle(
              title: 'Reading Progress',
              subtitle: 'Books you\'re reading and your current status',
              value: _shareReadingProgress,
              onChanged: (value) {
                setState(() => _shareReadingProgress = value);
              },
            ),

            const SizedBox(height: 12),

            _buildSharingToggle(
              title: 'Spice Ratings',
              subtitle: 'Your personal spice meter ratings for books',
              value: _shareSpiceRatings,
              onChanged: (value) {
                setState(() => _shareSpiceRatings = value);
              },
            ),

            const SizedBox(height: 12),

            _buildSharingToggle(
              title: 'Hard Stops',
              subtitle: 'Your personal hard stops and content triggers',
              value: _shareHardStops,
              onChanged: (value) {
                setState(() => _shareHardStops = value);
              },
              warning: 'Hard stops are sensitive. Only share with trusted friends.',
            ),

            const SizedBox(height: 12),

            _buildSharingToggle(
              title: 'Reviews & Notes',
              subtitle: 'Your personal book reviews and notes',
              value: _shareReviews,
              onChanged: (value) {
                setState(() => _shareReviews = value);
              },
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePreferences,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Preferences'),
              ),
            ),

            const SizedBox(height: 16),

            // Remove Friend Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _removeFriend,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Remove Friend'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSharingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? warning,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
            if (warning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return 'on ${date.month}/${date.day}';
    }
  }
}
