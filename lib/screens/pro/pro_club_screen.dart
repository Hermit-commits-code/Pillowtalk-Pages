// lib/screens/pro/pro_club_screen.dart

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../services/iap_service.dart';
import '../../widgets/free_trial_widgets.dart';

class ProClubScreen extends StatefulWidget {
  const ProClubScreen({super.key});

  @override
  State<ProClubScreen> createState() => _ProClubScreenState();
}

class _ProClubScreenState extends State<ProClubScreen> {
  final IAPService _iapService = IAPService();
  List<ProductDetails> _products = [];
  bool _loading = true;
  String? _error;
  bool isOnFreeTrial = false;
  int trialDaysLeft = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _iapService.getProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "The Connoisseur's Club",
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Column(
        children: [
          if (isOnFreeTrial)
            FreeTrialBanner(
              daysLeft: trialDaysLeft,
              onManage: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Manage your subscription below.'),
                  ),
                );
              },
              onDismiss: () {
                setState(() => isOnFreeTrial = false);
              },
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  color: theme.cardTheme.color,
                  shape: theme.cardTheme.shape,
                  elevation: theme.cardTheme.elevation,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_stories,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unlock the Ultimate Romance Reader Experience',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          color: theme.colorScheme.secondary,
                          thickness: 1.2,
                        ),
                        const SizedBox(height: 20),
                        _featureRow(theme, 'Unlimited book tracking'),
                        _featureRow(theme, 'Full Deep Tropes Engine (3+ tags)'),
                        _featureRow(theme, 'Advanced analytics & stats'),
                        _featureRow(theme, 'Exclusive luxury themes'),
                        _featureRow(theme, 'Ad-free sanctuary'),
                        const SizedBox(height: 24),
                        if (_loading)
                          const CircularProgressIndicator()
                        else if (_error != null)
                          Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          )
                        else if (_products.isEmpty)
                          Column(
                            children: [
                              Text(
                                'No purchase options available. Please check your store setup or try again later.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.surface,
                                  foregroundColor: theme.colorScheme.onSurface,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  textStyle: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'This is a placeholder. Configure IAP products in the store.',
                                      ),
                                      backgroundColor:
                                          theme.colorScheme.surface,
                                    ),
                                  );
                                },
                                child: const Text('Upgrade to Pro (Test)'),
                              ),
                            ],
                          )
                        else
                          ..._products.map(
                            (product) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.surface,
                                  foregroundColor: theme.colorScheme.onSurface,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  textStyle: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  try {
                                    await _iapService.buy(product);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Purchase failed: $e'),
                                          backgroundColor:
                                              theme.colorScheme.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  '${_formatPlanName(product)} – ${product.price}',
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Cancel anytime. Your sanctuary, your rules.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPlanName(ProductDetails product) {
    final title = product.title;
    final regex = RegExp(
      r'(Pro\s+Annual|Pro\s+Monthly|Annual|Monthly)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(title);
    if (match != null) {
      final plan = match.group(0)!;
      return plan.startsWith('Pro') ? plan.trim() : 'Pro $plan'.trim();
    }
    return 'Pro Subscription';
  }

  Widget _featureRow(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.secondary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
