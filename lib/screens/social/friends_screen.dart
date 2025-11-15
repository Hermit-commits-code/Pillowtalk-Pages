import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/friend.dart';
import '../../services/auth_service.dart';
import '../../services/friends_service.dart';

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
    // Require user to be signed in before attempting callable
    final user = AuthService.instance.currentUser;
    if (user == null) {
      setState(
        () => _addFriendError = 'Please sign in to send friend requests.',
      );
      return;
    }
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
      debugPrint('[Friends] Attempting to send friend request to: $email');

      // Try a safe, indexed lookup document `users_by_email/{normalizedEmail}`
      // to avoid client queries against the full `users` collection which
      // may be blocked by security rules. If the helper doc isn't present
      // fall back to a direct query (may be denied by rules).
      String normalize(String e) => e.toLowerCase().trim().replaceAll('.', ',');
      final normalized = normalize(email);
      String? targetUid;

      try {
        final mapDoc = await FirebaseFirestore.instance
            .collection('users_by_email')
            .doc(normalized)
            .get();

        if (mapDoc.exists) {
          final data = mapDoc.data();
          targetUid = data?['uid'] as String?;
        }
      } catch (e) {
        // Reading the mapping doc should be permitted by rules; if it fails
        // we'll fall back to a query below.
        debugPrint('[Friends] users_by_email lookup failed: $e');
      }

      if (targetUid == null) {
        // Fallback: try querying the users collection directly. This may be
        // blocked by Firestore rules, in which case we'll show a helpful
        // message to the user.
        try {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email.toLowerCase().trim())
              .limit(1)
              .get();

          if (query.docs.isEmpty) {
            if (mounted) {
              setState(() {
                _addFriendError = 'No user found with that email.';
                _isAddingFriend = false;
              });
            }
            return;
          }

          targetUid = query.docs.first.id;
        } on FirebaseException catch (fe) {
          if (fe.code == 'permission-denied') {
            if (mounted) {
              setState(() {
                _addFriendError =
                    'Unable to search by email from this device due to security settings.\n\nPlease ask the recipient to share their profile or ask an admin to populate the `users_by_email` mapping.';
                _isAddingFriend = false;
              });
            }
            return;
          }
          rethrow;
        }
      }

      if (targetUid == user.uid) {
        if (mounted) {
          setState(() {
            _addFriendError = 'You cannot add yourself as a friend.';
            _isAddingFriend = false;
          });
        }
        return;
      }

      // Verify the target user exists before sending the request
      try {
        final targetUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .get();

        if (!targetUserDoc.exists) {
          if (mounted) {
            setState(() {
              _addFriendError = 'User no longer exists or account is inactive.';
              _isAddingFriend = false;
            });
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _addFriendError = 'Unable to verify user exists: $e';
            _isAddingFriend = false;
          });
        }
        return;
      }

      // Create a pending friend request under the target user's friends
      // collection. The recipient will see this in their pending stream.
      await _friendsService.sendFriendRequestToUser(targetUid);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
      _emailController.clear();
      if (mounted) {
        context.pop();
      }
      if (mounted) {
        setState(() => _isAddingFriend = false);
      }
    } catch (e, st) {
      debugPrint('[Friends] Error sending friend request: $e');
      debugPrint(st.toString());

      if (mounted) {
        setState(() {
          _addFriendError = 'Failed to send friend request: $e';
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
          isScrollable: false,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
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
    // Fetch the sender's display name from Firestore
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(friend.friendId)
          .get(),
      builder: (context, snapshot) {
        String displayName = 'Friend';
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          displayName = userData?['displayName'] as String? ?? 'Friend';
        }

        return ListTile(
          leading: CircleAvatar(
            child: Text(displayName.substring(0, 1).toUpperCase()),
          ),
          title: Text(displayName),
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
      },
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
