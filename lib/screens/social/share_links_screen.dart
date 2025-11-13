import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/share_link.dart';
import '../../services/share_links_service.dart';

class ShareLinksScreen extends StatefulWidget {
  const ShareLinksScreen({super.key});

  @override
  State<ShareLinksScreen> createState() => _ShareLinksScreenState();
}

class _ShareLinksScreenState extends State<ShareLinksScreen> {
  final ShareLinksService _shareLinksService = ShareLinksService();
  bool _isCreating = false;

  Future<void> _createShareLink({
    required String type,
    required String title,
  }) async {
    setState(() => _isCreating = true);

    try {
      final shareLink = await _shareLinksService.createShareLink(
        type: type,
        expirationDays: 30,
        metadata: {
          'title': title,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;

      // Show confirmation dialog with share link
      _showShareDialog(shareLink);
      setState(() => _isCreating = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isCreating = false);
      }
    }
  }

  void _showShareDialog(ShareLink shareLink) {
    final shareUrl = 'https://spicyreads.app/share/${shareLink.shareId}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Link Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expires: ${_formatDate(shareLink.expiresAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                shareUrl,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Anyone with this link can view your ${shareLink.type.replaceAll('-', ' ')} for 30 days.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareUrl));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard!')),
              );
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Share Links')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Share Your Reading',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create temporary, expiring links to share your reading data with anyone.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 24),

            // Create Share Link Options
            _buildShareLinkOption(
              icon: Icons.bar_chart,
              title: 'Reading Progress',
              subtitle: 'Share your reading stats and currently reading books',
              onTap: () => _createShareLink(
                type: 'reading-progress',
                title: 'Reading Progress',
              ),
            ),

            const SizedBox(height: 12),

            _buildShareLinkOption(
              icon: Icons.flag,
              title: 'Reading Goal',
              subtitle: 'Share your reading goal and progress toward it',
              onTap: () =>
                  _createShareLink(type: 'reading-goal', title: 'Reading Goal'),
            ),

            const SizedBox(height: 12),

            _buildShareLinkOption(
              icon: Icons.library_add,
              title: 'To Be Read (TBR)',
              subtitle: 'Share your TBR pile with a friend',
              onTap: () =>
                  _createShareLink(type: 'spicy-tbr', title: 'TBR Pile'),
            ),

            const SizedBox(height: 32),

            // Active Share Links
            Text(
              'Active Links',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildActiveLinks(),

            const SizedBox(height: 32),

            // Info Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Link Details',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Links expire in 30 days\n• Anyone with the link can view (read-only)\n• You can revoke anytime\n• Access count is tracked',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
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

  Widget _buildShareLinkOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: _isCreating ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (_isCreating)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveLinks() {
    return StreamBuilder<List<ShareLink>>(
      stream: _shareLinksService.getMyShareLinksStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final links = snapshot.data ?? [];

        if (links.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.link_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No active share links',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: links.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final link = links[index];
            return _ShareLinkTile(
              shareLink: link,
              onRevoke: () => _revokeLink(link.shareId),
            );
          },
        );
      },
    );
  }

  Future<void> _revokeLink(String shareId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Link?'),
        content: const Text(
          'This link will no longer work. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _shareLinksService.revokeShareLink(shareId);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Link revoked')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Tile for displaying an active share link
class _ShareLinkTile extends StatelessWidget {
  final ShareLink shareLink;
  final VoidCallback onRevoke;

  const _ShareLinkTile({required this.shareLink, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final daysLeft = shareLink.expiresAt.difference(DateTime.now()).inDays;
    final metadata = shareLink.metadata;
    final title = metadata?['title'] ?? shareLink.type.replaceAll('-', ' ');

    return ListTile(
      leading: Icon(_getTypeIcon(shareLink.type)),
      title: Text(title),
      subtitle: Row(
        children: [
          Text(
            'Expires in $daysLeft days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: daysLeft <= 3 ? Colors.orange : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${shareLink.accessCount} views',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onRevoke,
        tooltip: 'Revoke',
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'reading-progress':
        return Icons.bar_chart;
      case 'reading-goal':
        return Icons.flag;
      case 'spicy-tbr':
        return Icons.library_add;
      default:
        return Icons.link;
    }
  }
}
