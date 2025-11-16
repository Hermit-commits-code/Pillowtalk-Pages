import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_update.dart';

/// Dismissible banner widget that appears at the top of the screen
/// when a new app version is available
class UpdateNotificationBanner extends StatefulWidget {
  final AppUpdate update;
  final VoidCallback? onDismiss;
  final bool isRequired; // If true, user cannot dismiss

  const UpdateNotificationBanner({
    super.key,
    required this.update,
    this.onDismiss,
    this.isRequired = false,
  });

  @override
  State<UpdateNotificationBanner> createState() =>
      _UpdateNotificationBannerState();
}

class _UpdateNotificationBannerState extends State<UpdateNotificationBanner> {
  bool _isDismissed = false;

  Future<void> _launchDownloadUrl() async {
    final url = Uri.parse(widget.update.downloadUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open download link')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary.withAlpha((0.95 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.system_update,
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'New version available (v${widget.update.latestVersion})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.update.releaseNotes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.update.releaseNotes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _launchDownloadUrl,
              child: Text(
                'Download',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!widget.isRequired) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _isDismissed = true);
                    widget.onDismiss?.call();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen dialog for required updates
/// User cannot dismiss; must download to continue
class UpdateRequiredDialog extends StatelessWidget {
  final AppUpdate update;

  const UpdateRequiredDialog({super.key, required this.update});

  Future<void> _launchDownloadUrl(BuildContext context) async {
    final url = Uri.parse(update.downloadUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open download link')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // Prevent back navigation
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.system_update_alt,
              color: theme.colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update Required',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version (v${update.latestVersion}) is required to continue using Spicy Reads.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (update.releaseNotes.isNotEmpty) ...[
                Text(
                  'What\'s New:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    update.releaseNotes,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _launchDownloadUrl(context),
            icon: const Icon(Icons.download),
            label: const Text('Download Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
