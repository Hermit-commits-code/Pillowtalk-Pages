// lib/screens/profile/profile_screen.dart
// Profile screen UI. Uses explicit mounted checks before using context
// after async gaps to satisfy analyzer.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../webview/docs_webview_screen.dart';
import '../onboarding/onboarding_flow.dart';

import '../../services/auth_service.dart';
import '../../services/hard_stops_service.dart';
import '../../services/kink_filter_service.dart';
import '../../services/theme_provider.dart';
import '../../services/audible_affiliate_service.dart';
import '../admin/developer_tools_screen.dart';
import '../librarian/librarian_tools_screen.dart';

class ProfileScreen extends StatefulWidget {
  /// Optional provider for the current Firebase [User]. Tests can inject
  /// a fake user by passing a closure here.
  final User? Function()? currentUserGetter;
  final dynamic authService;
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
  bool _isLibrarian = false;
  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadHardStops();
    _loadKinkFilters();
    _loadUserFlags();
  }

  // Load user-specific flags such as whether the user is a librarian
  Future<void> _loadUserFlags() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) {
        return;
      }
      setState(() {
        _isLibrarian = (doc.data()?['librarian'] ?? false) as bool;
        _analyticsEnabled = (doc.data()?['analyticsEnabled'] as bool?) ?? true;
      });
      // Update audible service cache
      AudibleAffiliateService().setUserAnalyticsEnabled(user.uid, _analyticsEnabled);
    } catch (_) {
      // ignore; default to false
    }
  }

  Future<void> _loadKinkFilters() async {
    try {
      final svc = KinkFilterService();
      final result = await svc.getKinkFilterOnce();
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
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
    if (!mounted) {
      return;
    }
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  // Pro upgrade banner removed — kept for future reintroduction if needed.

  void _logout(BuildContext context) async {
    // Capture router and messenger before any async gaps so we don't use
    // BuildContext across awaits.
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
        if (!mounted) {
          return;
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('Logout failed. Please try again.')),
        );
        return;
      }
      if (!mounted) {
        return;
      }
      router.go('/login');
    }
  }

  /// Try a list of candidate URLs in order until one successfully launches.
  /// If none succeed, offer copy or in-app WebView.
  void _launchUrlCandidates(List<String> candidates) async {
    debugPrint(
      'Attempting to open legal link candidates: ${candidates.join(', ')}',
    );
    for (final url in candidates) {
      final uri = Uri.tryParse(url);
      if (uri == null) continue;
      try {
        debugPrint('Checking canLaunch for $url');
        final can = await canLaunchUrl(uri);
        debugPrint('canLaunch($url) => $can');
        if (!can) continue;
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('launchUrl($url) => $launched');
        if (launched) return;
      } catch (_) {
        // Try next candidate
      }
    }

    if (!mounted) {
      return;
    }
    final choice = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open link'),
        content: const Text(
          'No external app could open this link. Would you like to open it inside the app or copy the URL?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('copy'),
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('inapp'),
            child: const Text('Open in app'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == 'copy') {
      if (candidates.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: candidates.first));
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
      return;
    }

    if (choice == 'inapp') {
      final target = candidates.isNotEmpty
          ? candidates.first
          : 'https://hermit-commits-code.github.io/Spicy-Reads/';
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocsWebViewScreen(initialUrl: target),
        ),
      );
      return;
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
            onChanged: (val) => localThemeProvider.setTheme(
              val ? ThemeMode.dark : ThemeMode.light,
            ),
            secondary: const Icon(Icons.brightness_6),
          ),
          SwitchListTile(
            title: const Text('Allow analytics & affiliate tracking'),
            subtitle: const Text(
              'Enable anonymous analytics and allow affiliate link clicks to be recorded for internal reporting. You can opt out at any time.',
            ),
            value: _analyticsEnabled,
            onChanged: (val) async {
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _analyticsEnabled = val);
              try {
                final user = AuthService.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({'analyticsEnabled': val, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
                  AudibleAffiliateService().setUserAnalyticsEnabled(user.uid, val);
                }
              } catch (e) {
                debugPrint('Failed to persist analytics preference: $e');
                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('Failed to save analytics preference')));
              }
            },
            secondary: const Icon(Icons.bar_chart),
          ),
          const Divider(height: 32),
          Text('Legal', style: theme.textTheme.titleMedium),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => _launchUrlCandidates([
              'https://hermit-commits-code.github.io/Spicy-Reads/PRIVACY_POLICY',
              'https://hermit-commits-code.github.io/Spicy-Reads/docs/PRIVACY_POLICY',
              'https://hermit-commits-code.github.io/Spicy-Reads/docs/PRIVACY_POLICY.html',
              'https://hermit-commits-code.github.io/Spicy-Reads/docs/PRIVACY_POLICY.md',
              'https://hermit-commits-code.github.io/Spicy-Reads/docs/',
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => _launchUrlCandidates([
              'https://hermit-commits-code.github.io/Spicy-Reads/TERMS_OF_SERVICE',
              'https://hermit-commits-code.github.io/Spicy-Reads/docs/TERMS_OF_SERVICE',
              'https://hermit-commits-code.github.io/Spicy-Reads/docs/TERMS_OF_SERVICE.html',
              'https://hermit-commits-code.github.io/Spicy-Reads/docs/TERMS_OF_SERVICE.md',
              'https://hermit-commits-code.github.io/Spicy-Reads/docs/',
            ]),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_calendar),
            title: const Text('Edit Onboarding'),
            subtitle: const Text(
              'Update your hard stops, kink filters, and favorites',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const OnboardingFlow())),
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
              if (!mounted) {
                return;
              }
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

          // Kinks UI: visible only when enabled
          if (_kinkFilterEnabled) ...[
            const SizedBox(height: 8),
            const Text('Common kinks — check to hide.'),
            const SizedBox(height: 8),
            ..._buildCommonKinks(theme),
            const SizedBox(height: 8),
            ..._buildCustomKinks(theme),
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
                      // Build canonical list: keep built-ins in order,
                      // sort customs alphabetically.
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

                      setState(() => _kinkFilters.add(text));
                      FocusScope.of(context).unfocus();

                      final presentCommon = commonKinks
                          .where((c) => _kinkFilters.contains(c))
                          .toList();
                      final custom =
                          _kinkFilters
                              .where((k) => !commonKinks.contains(k))
                              .toList()
                            ..sort(
                              (a, b) =>
                                  a.toLowerCase().compareTo(b.toLowerCase()),
                            );
                      final ordered = [...presentCommon, ...custom];

                      try {
                        await KinkFilterService().setKinkFilter(ordered);
                      } catch (e, st) {
                        debugPrint('Failed to persist kink filter: $e\n$st');
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Added locally but failed to save'),
                          ),
                        );
                        _customKinkController.clear();
                        return;
                      }

                      setState(() => _kinkFilters = ordered);
                      _customKinkController.clear();
                      if (!mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Added kink filter')),
                      );
                      debugPrint('kink filters after add: $_kinkFilters');
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Kink filters are disabled — no kink filtering will be applied.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
          ],

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
          if (_hardStopsEnabled) ...[
            const Text('Common warnings — check any you want to hide.'),
            const SizedBox(height: 8),
            ..._buildCommonHardStops(theme),
            const SizedBox(height: 8),
            // Render any custom hard stops the user added (alphabetized).
            ..._buildCustomHardStops(theme),
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
                      FocusScope.of(context).unfocus();

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

                      final presentCommon = commonContentWarnings
                          .where((c) => _hardStops.contains(c))
                          .toList();
                      final custom =
                          _hardStops
                              .where((h) => !commonContentWarnings.contains(h))
                              .toList()
                            ..sort(
                              (a, b) =>
                                  a.toLowerCase().compareTo(b.toLowerCase()),
                            );
                      final ordered = [...presentCommon, ...custom];

                      try {
                        await HardStopsService().setHardStops(ordered);
                      } catch (e, st) {
                        debugPrint('Failed to persist hard stop: $e\n$st');
                        if (!mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Added locally but failed to save'),
                          ),
                        );
                        _customHardStopController.clear();
                        return;
                      }

                      setState(() => _hardStops = ordered);
                      _customHardStopController.clear();
                      if (!mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Added hard stop')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Content filters are disabled — hard stops will not be applied.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 16),

          // Developer Tools (only visible to developer)
          if (user?.email == 'hotcupofjoe2013@gmail.com') ...[
            const Divider(height: 32),
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.red[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Developer Tools',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.build, color: Colors.orange[700]),
                      title: const Text('Admin Panel'),
                      subtitle: const Text(
                        'User management, ASIN tools, system controls',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DeveloperToolsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Librarian Tools (visible to any user marked as librarian)
          if (_isLibrarian) ...[
            const SizedBox(height: 8),
            const Divider(height: 32),
            Row(
              children: [
                Icon(Icons.library_books, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Librarian Tools',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.book, color: Colors.blue[700]),
                      title: const Text('Librarian Panel'),
                      subtitle: const Text(
                        'Verify books and ASINs, moderate entries',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LibrarianToolsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

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

  List<Widget> _buildCustomHardStops(ThemeData theme) {
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

    final custom = _hardStops
        .where((h) => !commonContentWarnings.contains(h))
        .toList();
    if (custom.isEmpty) return [];

    custom.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return custom.map((warning) {
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
            if (!_kinkFilters.contains(k)) {
              setState(() => _kinkFilters.add(k));
            }
          } else {
            setState(() => _kinkFilters.remove(k));
          }
          await KinkFilterService().setKinkFilter(_kinkFilters);
        },
        controlAffinity: ListTileControlAffinity.leading,
      );
    }).toList();
  }

  List<Widget> _buildCustomKinks(ThemeData theme) {
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

    final custom = _kinkFilters.where((k) => !commonKinks.contains(k)).toList();
    if (custom.isEmpty) return [];

    // Keep alphabetical order for custom items
    custom.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return custom.map((k) {
      final checked = _kinkFilters.contains(k);
      return CheckboxListTile(
        title: Text(k, style: theme.textTheme.bodyMedium),
        value: checked,
        onChanged: (val) async {
          if (val == true) {
            if (!_kinkFilters.contains(k)) {
              setState(() => _kinkFilters.add(k));
            }
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
