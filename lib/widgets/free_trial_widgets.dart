import 'package:flutter/material.dart';

/// FreeTrialBanner: Elegant, luxury banner for free trial status
class FreeTrialBanner extends StatelessWidget {
  final int daysLeft;
  final VoidCallback? onManage;
  final VoidCallback? onDismiss;

  const FreeTrialBanner({
    Key? key,
    required this.daysLeft,
    this.onManage,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondary.withOpacity(0.15),
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.secondary, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.stars, color: theme.colorScheme.secondary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                daysLeft > 1
                    ? "You're enjoying a free trial of Spicy Reads Pro! $daysLeft days left."
                    : "Your free trial ends today!",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (onManage != null)
              TextButton(
                onPressed: onManage,
                child: Text(
                  'Manage',
                  style: TextStyle(color: theme.colorScheme.secondary),
                ),
              ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close),
                color: theme.colorScheme.secondary,
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}

/// FreeTrialModal: Modal dialog for trial start/end
void showFreeTrialModal(
  BuildContext context, {
  required bool isEnding,
  required int daysLeft,
}) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.stars, color: theme.colorScheme.secondary, size: 32),
          const SizedBox(width: 10),
          Text(
            isEnding ? 'Free Trial Ending' : 'Welcome to Pro!',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnding
                ? "Your free trial of Spicy Reads Pro is ending soon."
                : "You’re enjoying a free trial of Spicy Reads Pro!",
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            isEnding
                ? (daysLeft == 0
                      ? "Your trial ends today. Subscribe to keep your Pro benefits!"
                      : "You have $daysLeft day(s) left.")
                : "You have $daysLeft day(s) of Pro access.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Pro Benefits:",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ...[
            "Unlimited book tracking",
            "Full Deep Tropes Engine (3+ tags)",
            "Advanced analytics & stats",
            "Exclusive luxury themes",
            "Ad-free sanctuary",
          ].map(
            (b) => Row(
              children: [
                Icon(Icons.check, color: theme.colorScheme.secondary, size: 18),
                const SizedBox(width: 6),
                Text(b, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isEnding
                ? "You can manage or cancel your subscription anytime in the Play Store."
                : "Cancel anytime. Your sanctuary, your rules.",
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Got it',
            style: TextStyle(color: theme.colorScheme.secondary),
          ),
        ),
      ],
    ),
  );
}
