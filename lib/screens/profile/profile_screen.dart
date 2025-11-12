// lib/screens/profile/profile_screen.dart
// Profile screen UI. Use explicit mounted checks before using context
// after async gaps to satisfy analyzer.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';
import '../../services/hard_stops_service.dart';
import '../../services/kink_filter_service.dart';
import '../../services/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  /// Optional provider for the current Firebase [User]. Tests should pass a
  /// closure returning null or a fake [User] to avoid initializing real
  /// Firebase services. Alternatively, tests can inject an `authService`
  /// which exposes `currentUser`, `signOut`, etc.
  final User? Function()? currentUserGetter;
  final dynamic authService;

  /// Optional theme provider injection for tests. If not provided the
  /// real `Provider.of<ThemeProvider>` is used.
  final dynamic themeProvider;

  const ProfileScreen({
    super.key,
    this.currentUserGetter,
    this.authService,
    this.themeProvider,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _appVersion = '';
  List<String> _hardStops = [];
  bool _hardStopsEnabled = true;
  final TextEditingController _customHardStopController =
      TextEditingController();
  // Kink filter state
  List<String> _kinkFilters = [];
  bool _kinkFilterEnabled = true;
  final TextEditingController _customKinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadHardStops();
    _loadKinkFilters();
  }

  Future<void> _loadKinkFilters() async {
    try {
      final svc = KinkFilterService();
      final result = await svc.getKinkFilterOnce();
      if (!mounted) return;
      setState(() {
        _kinkFilters = List<String>.from(result['kinkFilter'] as List<String>);
        _kinkFilterEnabled = result['enabled'] as bool;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadHardStops() async {
    try {
      final svc = HardStopsService();
      final result = await svc.getHardStopsOnce();
      if (!mounted) return;
      setState(() {
        _hardStops = List<String>.from(result['hardStops'] as List<String>);
        _hardStopsEnabled = result['enabled'] as bool;
      });
    } catch (_) {
      // ignore; leave defaults
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  void _logout(BuildContext context) async {
    // Capture router and messenger before any async gaps so we don't use
    // BuildContext across awaits (satisfies use_build_context_synchronously).
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final svc = widget.authService;
        if (svc != null) {
          await svc.signOut();
        } else {
          await AuthService.instance.signOut();
        }
      } catch (e) {
        // Sign-out should rarely fail; surface a user-friendly message and
        // keep the user on the profile screen so they can retry.
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Logout failed. Please try again.')),
        );
        // Optionally log the error to analytics/logging here.
        return;
      }
      if (!mounted) return;
      router.go('/login');
    }
  }

  void _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        ).catchError((e) {
          // Handle launch errors gracefully
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $url')),
          );
          return false;
        });
      } else {
        // URL cannot be launched
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    } catch (e) {
      // Handle any parsing or other errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening link: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUserGetter != null
        ? widget.currentUserGetter!.call()
        : widget.authService != null
        ? widget.authService.currentUser
        : AuthService.instance.currentUser;
    final theme = Theme.of(context);
    final displayName = user?.displayName ?? user?.email ?? 'Reader';
    final userId = user?.uid ?? '';
    final localThemeProvider =
        widget.themeProvider ?? Provider.of<ThemeProvider>(context);
    final isDark = localThemeProvider.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Text(displayName, style: theme.textTheme.titleLarge),
                if (userId.isNotEmpty)
                  Text(
                    'User ID: $userId',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    // Explicit textStyle avoids an implicit TextStyle inheritance
                    // mismatch during animated transitions which caused a
                    // TextStyle.lerp error in some theme configurations.
                    textStyle: theme.textTheme.titleMedium,
                  ),
                  onPressed: () => _logout(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Settings', style: theme.textTheme.titleMedium),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDark,
            onChanged: (val) {
              localThemeProvider.setTheme(
                val ? ThemeMode.dark : ThemeMode.light,
              );
            },
            secondary: const Icon(Icons.brightness_6),
          ),
          const Divider(height: 32),
          Text('Legal', style: theme.textTheme.titleMedium),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => _launchUrl(
              'https://hermit-commits-code.github.io/Spicy-Reads/docs/PRIVACY_POLICY.md',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => _launchUrl(
              'https://hermit-commits-code.github.io/Spicy-Reads/docs/TERMS_OF_SERVICE.md',
            ),
          ),
          const SizedBox(height: 16),
          Text('Kink Filters', style: theme.textTheme.titleMedium),
          SwitchListTile(
            title: const Text('Enable kink filters'),
            value: _kinkFilterEnabled,
            onChanged: (val) async {
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _kinkFilterEnabled = val);
              await KinkFilterService().setKinkFilterEnabled(val);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    val ? 'Kink filters enabled' : 'Kink filters disabled',
                  ),
                ),
              );
            },
            secondary: const Icon(Icons.local_fire_department_outlined),
          ),
          const SizedBox(height: 8),
          const Text('Common kinks — check to hide.'),
          const SizedBox(height: 8),
          ..._buildCommonKinks(theme),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customKinkController,
                  decoration: const InputDecoration(
                    labelText: 'Add custom kink',
                    hintText: 'e.g. Tentacles',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final text = _customKinkController.text.trim();
                  if (text.isEmpty) return;
                  if (!_kinkFilters.contains(text)) {
                    setState(() => _kinkFilters.add(text));
                    await KinkFilterService().setKinkFilter(_kinkFilters);
                    _customKinkController.clear();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Added kink filter')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
          Text('Content Filters', style: theme.textTheme.titleMedium),
          SwitchListTile(
            title: const Text('Enable content filters (Hard Stops)'),
            value: _hardStopsEnabled,
            onChanged: (val) async {
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _hardStopsEnabled = val);
              await HardStopsService().setHardStopsEnabled(val);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    val
                        ? 'Content filters enabled'
                        : 'Content filters disabled',
                  ),
                ),
              );
            },
            secondary: const Icon(Icons.shield_outlined),
          ),
          const SizedBox(height: 8),
          Text(
            'Hard Stops (Content Warnings)',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          const Text('Common warnings — check any you want to hide.'),
          const SizedBox(height: 8),
          // A small built-in list of common warnings; keep it short and editable
          ..._buildCommonHardStops(theme),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customHardStopController,
                  decoration: const InputDecoration(
                    labelText: 'Add custom hard stop',
                    hintText: 'e.g. Infidelity',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final text = _customHardStopController.text.trim();
                  if (text.isEmpty) return;
                  if (!_hardStops.contains(text)) {
                    setState(() => _hardStops.add(text));
                    await HardStopsService().setHardStops(_hardStops);
                    _customHardStopController.clear();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Added hard stop')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'App Version: $_appVersion',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCommonHardStops(ThemeData theme) {
    const List<String> commonContentWarnings = [
      'Infidelity/Cheating',
      'Violence/Abuse',
      'Sexual Assault',
      'Dubious Consent',
      'Death of Parent/Child',
      'Self-Harm',
      'Substance Abuse',
      'Mental Illness',
      'Graphic Sex',
      'BDSM',
    ];

    return commonContentWarnings.map((warning) {
      final checked = _hardStops.contains(warning);
      return CheckboxListTile(
        title: Text(warning, style: theme.textTheme.bodyMedium),
        value: checked,
        onChanged: (val) async {
          if (val == true) {
            if (!_hardStops.contains(warning)) {
              setState(() => _hardStops.add(warning));
            }
          } else {
            setState(() => _hardStops.remove(warning));
          }
          await HardStopsService().setHardStops(_hardStops);
        },
        controlAffinity: ListTileControlAffinity.leading,
      );
    }).toList();
  }

  List<Widget> _buildCommonKinks(ThemeData theme) {
    const List<String> commonKinks = [
      'CNC (Consensual Non-Consent)',
      'Breeding Kink',
      'Pet Play',
      'Daddy/Mommy Kink',
      'Age Play',
      'Exhibitionism',
      'Voyeurism',
      'Praise/Degradation',
      'Bondage',
      'Impact Play',
      'Choking',
      'Spanking',
      'Medical Play',
      'Watersports',
      'Humiliation',
      'Public Sex',
      'Group Sex/Orgy',
      'Incest Roleplay',
      'Monster Romance',
      'Tentacles',
      'Omegaverse',
    ];

    return commonKinks.map((k) {
      final checked = _kinkFilters.contains(k);
      return CheckboxListTile(
        title: Text(k, style: theme.textTheme.bodyMedium),
        value: checked,
        onChanged: (val) async {
          if (val == true) {
            if (!_kinkFilters.contains(k)) setState(() => _kinkFilters.add(k));
          } else {
            setState(() => _kinkFilters.remove(k));
          }
          await KinkFilterService().setKinkFilter(_kinkFilters);
        },
        controlAffinity: ListTileControlAffinity.leading,
      );
    }).toList();
  }

  @override
  void dispose() {
    _customKinkController.dispose();
    _customHardStopController.dispose();
    super.dispose();
  }
}
