import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/friend.dart';
import '../../services/friends_service.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendsService _friendsService = FriendsService();
  final TextEditingController _emailController = TextEditingController();
  bool _isAddingFriend = false;
  String? _addFriendError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendFriendRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _addFriendError = 'Please enter an email');
      return;
    }

    setState(() {
      _isAddingFriend = true;
      _addFriendError = null;
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendFriendRequestByEmail',
      );
      final result = await callable.call(<String, dynamic>{'email': email});
      final data = result.data as Map<String, dynamic>?;

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _addFriendError = 'Unexpected response from server.';
          _isAddingFriend = false;
        });
        return;
      }

      if (data['found'] == false) {
        setState(() {
          _addFriendError = 'No user found with that email.';
          _isAddingFriend = false;
        });
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
      _emailController.clear();
      setState(() => _isAddingFriend = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _addFriendError = 'Failed to send request: ${e.toString()}';
          _isAddingFriend = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // theme variable removed — not used

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Friends Tab
          _buildFriendsList(),
          // Requests Tab
          _buildPendingRequests(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        tooltip: 'Add friend',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  /// Build the accepted friends list
  Widget _buildFriendsList() {
    return StreamBuilder<List<Friend>>(
      stream: _friendsService.getAcceptedFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Invite friends to share your reading journey',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: friends.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _FriendTile(
              friend: friend,
              onTap: () {
                context.push('/social/friend-settings/${friend.friendId}');
              },
            );
          },
        );
      },
    );
  }

  /// Build pending friend requests
  Widget _buildPendingRequests() {
    return StreamBuilder<List<Friend>>(
      stream: _friendsService.getPendingFriendRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final request = requests[index];
            return _PendingRequestTile(
              friend: request,
              onAccept: () => _acceptRequest(request.friendId),
              onDecline: () => _declineRequest(request.friendId),
            );
          },
        );
      },
    );
  }

  Future<void> _acceptRequest(String friendId) async {
    try {
      await _friendsService.acceptFriendRequest(friendId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request accepted!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _declineRequest(String friendId) async {
    try {
      await _friendsService.declineFriendRequest(friendId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request declined')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Friend\'s email',
                hintText: 'user@example.com',
                errorText: _addFriendError,
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _sendFriendRequest(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _emailController.clear();
              setState(() => _addFriendError = null);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isAddingFriend ? null : _sendFriendRequest,
            child: _isAddingFriend
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}

/// Tile for displaying an accepted friend
class _FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  const _FriendTile({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(friend.friendId.substring(0, 2).toUpperCase()),
      ),
      title: Text('Friend'),
      subtitle: Text(
        'Added ${friend.acceptedAt != null ? _formatDate(friend.acceptedAt!) : 'recently'}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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

/// Tile for displaying a pending friend request
class _PendingRequestTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _PendingRequestTile({
    required this.friend,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(friend.friendId.substring(0, 2).toUpperCase()),
      ),
      title: const Text('Friend Request'),
      subtitle: Text('Received ${_formatDate(friend.createdAt)}'),
      trailing: SizedBox(
        width: 120,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDecline,
              tooltip: 'Decline',
              splashRadius: 20,
            ),
            IconButton(
              icon: const Icon(Icons.check, size: 20, color: Colors.green),
              onPressed: onAccept,
              tooltip: 'Accept',
              splashRadius: 20,
            ),
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
