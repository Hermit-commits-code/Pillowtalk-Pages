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
    final input = _emailController.text.trim();
    if (input.isEmpty) {
      setState(() => _addFriendError = 'Please enter an email or username');
      return;
    }

    setState(() {
      _isAddingFriend = true;
      _addFriendError = null;
    });

    try {
      debugPrint('[Friends] Attempting to send friend request to: $input');

      // Try a safe, indexed lookup document `users_by_email/{normalizedEmail}`
      // first, then try `users_by_username/{normalizedUsername}`. These
      // mapping docs avoid client-side queries against large `users`
      // collections which might be restricted by rules.
      String normalizeEmail(String e) =>
          e.toLowerCase().trim().replaceAll('.', ',');
      String normalizeUsername(String u) => u.toLowerCase().trim();

      String? targetUid;

      // 1) users_by_email lookup (safe for emails)
      try {
        final normalizedEmail = normalizeEmail(input);
        final mapDoc = await FirebaseFirestore.instance
            .collection('users_by_email')
            .doc(normalizedEmail)
            .get();

        if (mapDoc.exists) {
          final data = mapDoc.data();
          targetUid = data?['uid'] as String?;
        }
      } catch (e) {
        debugPrint('[Friends] users_by_email lookup failed: $e');
      }

      // 2) users_by_username lookup (accepts @username or plain username)
      if (targetUid == null) {
        try {
          var candidate = input;
          if (candidate.startsWith('@')) candidate = candidate.substring(1);
          final normalized = normalizeUsername(candidate);
          final nameDoc = await FirebaseFirestore.instance
              .collection('users_by_username')
              .doc(normalized)
              .get();

          if (nameDoc.exists) {
            final data = nameDoc.data();
            targetUid = data?['uid'] as String?;
          }
        } catch (e) {
          debugPrint('[Friends] users_by_username lookup failed: $e');
        }
      }

      // 3) Fallback: try querying by email (if input looks like an email) or
      // by displayName if not. These queries may be denied by rules.
      if (targetUid == null) {
        try {
          if (input.contains('@')) {
            final query = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: input.toLowerCase().trim())
                .limit(1)
                .get();

            if (query.docs.isNotEmpty) targetUid = query.docs.first.id;
          } else {
            final query = await FirebaseFirestore.instance
                .collection('users')
                .where('displayName', isEqualTo: input.trim())
                .limit(1)
                .get();

            if (query.docs.isNotEmpty) targetUid = query.docs.first.id;
          }

          if (targetUid == null) {
            if (mounted) {
              setState(() {
                _addFriendError = 'No user found with that email or username.';
                _isAddingFriend = false;
              });
            }
            return;
          }
        } on FirebaseException catch (fe) {
          if (fe.code == 'permission-denied') {
            if (mounted) {
              setState(() {
                _addFriendError =
                    'Unable to search for users from this device due to security settings.\n\nPlease ask the recipient to share their profile or ask an admin to populate the mapping docs.';
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
    // Fetch the friend's username and displayName from Firestore
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(friend.friendId)
          .get(),
      builder: (context, snapshot) {
        String displayName = 'Friend';
        String? username;

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          displayName = userData?['displayName'] as String? ?? 'Friend';
          username = userData?['username'] as String?;
        }

        return ListTile(
          leading: CircleAvatar(
            child: Text(displayName.substring(0, 1).toUpperCase()),
          ),
          title: Text(username != null ? '@$username' : displayName),
          subtitle: Text(
            'Added ${friend.acceptedAt != null ? _formatDate(friend.acceptedAt!) : 'recently'}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
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
