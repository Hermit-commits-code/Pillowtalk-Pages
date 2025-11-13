// lib/screens/admin/developer_tools_screen.dart
import 'package:flutter/material.dart';

import '../../services/user_management_service.dart';
import 'asin_management_screen.dart';
import '../onboarding/onboarding_flow.dart';

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
    setState(() => _isLoading = true);

    try {
      final proUsers = await _userService.getProUsers();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pro Users'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: proUsers.isEmpty
                ? const Center(child: Text('No Pro users found'))
                : ListView.builder(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
    setState(() => _isLoading = true);

    try {
      final librarians = await _userService.getLibrarians();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Librarians'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: librarians.isEmpty
                ? const Center(child: Text('No Librarians found'))
                : ListView.builder(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Developer-only tools. Use with caution.',
                      style: TextStyle(
                        color: Colors.red[700],
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
          ],
        ),
      ),
    );
  }

  /// Run a lightweight diagnostics ping to validate callable access
  Future<void> _runDiagnostics() async {
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
