import 'package:flutter/material.dart';
import '../models/app_update.dart';
import '../services/update_service.dart';
import '../widgets/update_notification.dart';

/// Wrapper widget that checks for app updates on initialization
/// and displays update notifications if available
class UpdateCheckWrapper extends StatefulWidget {
  final Widget child;

  const UpdateCheckWrapper({super.key, required this.child});

  @override
  State<UpdateCheckWrapper> createState() => _UpdateCheckWrapperState();
}

class _UpdateCheckWrapperState extends State<UpdateCheckWrapper> {
  final UpdateService _updateService = UpdateService();
  AppUpdate? _availableUpdate;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final update = await _updateService.checkForUpdate();

      if (!mounted) return;

      setState(() {
        _availableUpdate = update;
      });

      // Log update check result
      if (update != null) {
        // ignore: avoid_print
        print('Update available: v${update.latestVersion}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error in update check: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If required update is available, show blocking dialog
    if (_availableUpdate?.isRequired ?? false) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: UpdateRequiredDialog(update: _availableUpdate!)),
        ),
      );
    }

    // If optional update is available, prepend banner to child
    if (_availableUpdate != null && !_availableUpdate!.isRequired) {
      return Column(
        children: [
          UpdateNotificationBanner(
            update: _availableUpdate!,
            isRequired: false,
            onDismiss: () {
              setState(() => _availableUpdate = null);
            },
          ),
          Expanded(child: widget.child),
        ],
      );
    }

    // No update or still checking
    return widget.child;
  }
}
