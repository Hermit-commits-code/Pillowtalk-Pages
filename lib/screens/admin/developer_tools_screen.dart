// lib/screens/admin/developer_tools_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/admin.dart';
import '../../services/auth_service.dart';
import '../../services/user_management_service.dart';
import '../onboarding/onboarding_flow.dart';
import 'asin_management_screen.dart';

/// Developer-only admin tools screen
/// Accessible only to hotcupofjoe2013@gmail.com
class DeveloperToolsScreen extends StatefulWidget {
  const DeveloperToolsScreen({super.key});

  @override
  State<DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends State<DeveloperToolsScreen> {
  final UserManagementService _userService = UserManagementService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _selectedUser;
  // _searchResults removed: search UI not used currently
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkDeveloperAccess();
  }

  /// Verify developer access
  void _checkDeveloperAccess() {
    if (!_userService.isDeveloper) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Developer access required'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // _searchUsers removed: not referenced by UI

  /// Get user by email
  Future<void> _getUserByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _selectedUser = null;
    });

    try {
      final user = await _userService.getUserByEmail(email);
      setState(() {
        _selectedUser = user;
        _statusMessage = user != null ? 'User found' : 'User not found';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${_formatError(e)}';
        _selectedUser = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Toggle Pro status for selected user
  Future<void> _toggleProStatus() async {
    if (_selectedUser == null) return;

    final currentStatus = _selectedUser!['proStatus'] as bool;
    final newStatus = !currentStatus;

    setState(() => _isLoading = true);

    try {
      await _userService.setProStatus(_selectedUser!['uid'], newStatus);
      setState(() {
        _selectedUser = {..._selectedUser!, 'proStatus': newStatus};
        _statusMessage = newStatus
            ? 'Granted Pro access'
            : 'Removed Pro access';
      });
    } catch (e) {
      setState(
        () =>
            _statusMessage = 'Failed to update Pro status: ${_formatError(e)}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Toggle Librarian status for selected user
  Future<void> _toggleLibrarianStatus() async {
    if (_selectedUser == null) return;

    final currentStatus = _selectedUser!['librarian'] as bool;
    final newStatus = !currentStatus;

    setState(() => _isLoading = true);

    try {
      await _userService.setLibrarianStatus(_selectedUser!['uid'], newStatus);
      setState(() {
        _selectedUser = {..._selectedUser!, 'librarian': newStatus};
        _statusMessage = newStatus
            ? 'Granted Librarian access'
            : 'Removed Librarian access';
      });
    } catch (e) {
      setState(
        () => _statusMessage =
            'Failed to update Librarian status: ${_formatError(e)}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Navigate to ASIN management
  void _openASINManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AsinManagementScreen()),
    );
  }

  /// Show Pro users list
  Future<void> _showProUsers() async {
    // Pre-flight admin access and provide an actionable message if not available.
    if (!await _ensureAdminAccess()) return;

    setState(() => _isLoading = true);

    try {
      final proUsers = await _userService.getProUsers();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Pro Users'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(c).size.height * 0.7,
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: proUsers.isEmpty
                  ? const Center(child: Text('No Pro users found'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: proUsers.length,
                      itemBuilder: (context, index) {
                        final user = proUsers[index];
                        return ListTile(
                          title: Text(user['email'] ?? 'Unknown'),
                          subtitle: Text(user['displayName'] ?? 'No name'),
                          trailing: Text(
                            'Pro',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(
        () => _statusMessage = 'Failed to load Pro users: ${_formatError(e)}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Show Librarians list
  Future<void> _showLibrarians() async {
    if (!await _ensureAdminAccess()) return;

    setState(() => _isLoading = true);

    try {
      final librarians = await _userService.getLibrarians();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Librarians'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(c).size.height * 0.7,
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: librarians.isEmpty
                  ? const Center(child: Text('No Librarians found'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: librarians.length,
                      itemBuilder: (context, index) {
                        final user = librarians[index];
                        return ListTile(
                          title: Text(user['email'] ?? 'Unknown'),
                          subtitle: Text(user['displayName'] ?? 'No name'),
                          trailing: Text(
                            'Librarian',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(
        () => _statusMessage = 'Failed to load Librarians: ${_formatError(e)}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Launch the onboarding flow for testing
  void _runOnboarding() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (c) => const OnboardingFlow()));
  }

  String _formatError(Object e) {
    final s = e.toString();
    if (s.toLowerCase().contains('permission-denied') ||
        s.toLowerCase().contains('permission denied')) {
      return 'Permission denied — this action requires server-side/admin privileges. Consider running this from a secure admin console or Cloud Function using a service account.';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner (theme-aware)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Developer-only tools. Use with caution.',
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _openASINManagement,
                  icon: const Icon(Icons.link),
                  label: const Text('ASIN Management'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: _showProUsers,
                  icon: const Icon(Icons.star),
                  label: const Text('View Pro Users'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: _showLibrarians,
                  icon: const Icon(Icons.library_books),
                  label: const Text('View Librarians'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _runOnboarding,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run Onboarding'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAffiliateClicks,
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('View Affiliate Clicks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _runDiagnostics,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Diagnostics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // User Management
            Text(
              'User Management',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Email lookup
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find User by Email',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'user@example.com',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _getUserByEmail,
                          child: const Text('Find'),
                        ),
                      ],
                    ),

                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color:
                              _statusMessage.contains('Error') ||
                                  _statusMessage.contains('Failed')
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],

                    if (_selectedUser != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // User details
                      Text(
                        'User Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildUserDetailRow('Email:', _selectedUser!['email']),
                      _buildUserDetailRow(
                        'Display Name:',
                        _selectedUser!['displayName'] ?? 'Not set',
                      ),
                      _buildUserDetailRow('UID:', _selectedUser!['uid']),

                      const SizedBox(height: 16),

                      // Status toggles
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _toggleProStatus,
                              icon: Icon(
                                _selectedUser!['proStatus']
                                    ? Icons.star_outline
                                    : Icons.star,
                              ),
                              label: Text(
                                _selectedUser!['proStatus']
                                    ? 'Remove Pro'
                                    : 'Grant Pro',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedUser!['proStatus']
                                    ? Colors.red
                                    : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _toggleLibrarianStatus,
                              icon: Icon(
                                _selectedUser!['librarian']
                                    ? Icons.library_books_outlined
                                    : Icons.library_books,
                              ),
                              label: Text(
                                _selectedUser!['librarian']
                                    ? 'Remove Librarian'
                                    : 'Grant Librarian',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedUser!['librarian']
                                    ? Colors.red
                                    : Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 24),
            // Dev Utilities
            Text(
              'Dev Utilities',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showMyUid,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Show My UID'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(child: Text('Owner-only analytics')),
                        FutureBuilder<bool>(
                          future: _loadRuntimeRestrictFlag(),
                          builder: (context, snap) {
                            final val = snap.data ?? false;
                            return Switch(
                              value: val,
                              onChanged: (v) => _setRuntimeRestrictFlag(v),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Run a lightweight diagnostics ping to validate callable access
  Future<void> _runDiagnostics() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      setState(() => _statusMessage = 'Please sign in to run diagnostics.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final res = await _userService.pingAdmin();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Diagnostics'),
          content: Text(
            'OK\nUID: ${res['actorUid'] ?? 'unknown'}\nEmail: ${res['actorEmail'] ?? 'unknown'}\nTime: ${res['now'] ?? ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Diagnostics Error'),
          content: Text(_formatError(e)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Verify admin callable access. Shows a helpful dialog if access is unavailable.
  Future<bool> _ensureAdminAccess() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      setState(() => _statusMessage = 'Please sign in as the developer to use these tools.');
      return false;
    }

    try {
      setState(() => _isLoading = true);
      await _userService.pingAdmin();
      return true;
    } catch (e) {
      // Provide an actionable dialog explaining common fixes.
      if (!mounted) return false;
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Admin Access Unavailable'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatError(e)),
                const SizedBox(height: 12),
                const Text('Possible resolutions:'),
                const SizedBox(height: 8),
                const Text('• Sign in as the developer account (hotcupofjoe2013@gmail.com).'),
                const Text('• Ensure Cloud Functions are deployed and reachable.'),
                const Text('• Add your UID to the admin allow-list at `config/admins` in Firestore or set ADMIN_UIDS in the functions environment.'),
                const SizedBox(height: 8),
                const Text('If you need, run diagnostics from this screen to capture the exact error.'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close')),
          ],
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Show recent affiliate_clicks entries (read-only)
  Future<void> _showAffiliateClicks() async {
    if (!await _ensureAdminAccess()) return;

    setState(() => _isLoading = true);
    try {
      final q = FirebaseFirestore.instance
          .collection('affiliate_clicks')
          .orderBy('createdAt', descending: true)
          .limit(50);
      final snap = await q.get();
      final docs = snap.docs;
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Recent Affiliate Clicks'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(c).size.height * 0.75,
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: docs.isEmpty
                  ? const Center(child: Text('No clicks recorded'))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      separatorBuilder: (context, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final d = docs[index].data();
                        final ts = d['createdAt'];
                        final when = ts is Timestamp
                            ? ts.toDate().toString()
                            : (ts?.toString() ?? '');
                        return ListTile(
                          title: Text(
                            d['bookTitle'] ?? d['bookId'] ?? 'Unknown',
                          ),
                          subtitle: Text('${d['affiliateUrl'] ?? ''}\n$when'),
                          trailing: Text(d['userId'] ?? ''),
                          isThreeLine: true,
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        );
                      },
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load affiliate clicks: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showMyUid() async {
    final user = AuthService.instance.currentUser;
    final uid = user?.uid ?? 'not-signed-in';
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('My UID'),
        content: Text(uid),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool> _loadRuntimeRestrictFlag() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('admin')
          .get();
      if (!doc.exists) return kRestrictAnalyticsToOwners;
      final val = doc.data()?['restrictAnalyticsToOwners'];
      if (val is bool) return val;
    } catch (e) {
      debugPrint('Failed to load runtime restrict flag: $e');
    }
    return kRestrictAnalyticsToOwners;
  }

  Future<void> _setRuntimeRestrictFlag(bool v) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('admin')
          .set({'restrictAnalyticsToOwners': v}, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Owner-only analytics set to ${v ? 'ON' : 'OFF'}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save setting: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildUserDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
