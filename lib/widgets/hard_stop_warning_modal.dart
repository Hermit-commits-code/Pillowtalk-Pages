import 'package:flutter/material.dart';

enum HardStopChoice { cancel, showAnyway, addToIgnore }

Future<HardStopChoice?> showHardStopWarningDialog(BuildContext context, List<String> matchedWarnings) {
  return showDialog<HardStopChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(child: Text('Content Warning')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This book contains content that matches your hard stops.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: matchedWarnings.map((w) => Chip(
                  label: Text(w),
                  backgroundColor: Colors.orange.withOpacity(0.12),
                )).toList(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose an action. You can add these to an ignore list if you plan to tolerate them later.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(HardStopChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(HardStopChoice.addToIgnore),
            child: const Text('Add to Ignore List'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(HardStopChoice.showAnyway),
            child: const Text('Show Anyway'),
          ),
        ],
      );
    },
  );
}
