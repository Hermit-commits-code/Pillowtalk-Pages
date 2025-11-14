// lib/services/audible_affiliate_service.dart
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
// cloud_firestore already imported above; avoid duplicate import
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/user_book.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/admin.dart';

// Compile-time flag to disable analytics (set via --dart-define=DISABLE_ANALYTICS=true)
const bool kDisableAnalytics = bool.fromEnvironment(
  'DISABLE_ANALYTICS',
  defaultValue: false,
);

/// Service for handling Audible affiliate links and revenue tracking
class AudibleAffiliateService {
  static final AudibleAffiliateService _instance =
      AudibleAffiliateService._internal();
  factory AudibleAffiliateService() => _instance;
  AudibleAffiliateService._internal();

  // Replace with your actual Audible affiliate tag
  static const String _affiliateTag = 'spicyreads-20';
  static const String _audibleBaseUrl = 'https://www.audible.com';

  // Cache per-user runtime analytics preference to avoid hitting Firestore
  final Map<String, bool> _userAnalyticsCache = {};
  // Cached runtime flag from Firestore (optional override)
  bool? _runtimeRestrictAnalyticsCache;

  /// Generate Audible affiliate link for a book
  String generateAffiliateLink(UserBook book) {
    // Search URL with affiliate tag
    final searchQuery = Uri.encodeComponent(
      '${book.title} ${book.authors.join(' ')}',
    );
    return '$_audibleBaseUrl/search?keywords=$searchQuery&ref=a_search_c1_lProduct_1_1&pf_rd_p=83218cca-c308-412f-bfcf-90198b687a2f&pf_rd_r=&pageLoadId=&creativeId=&tag=$_affiliateTag';
  }

  /// Generate direct Audible link if we have an ASIN
  String generateDirectAffiliateLink(String asin) {
    return '$_audibleBaseUrl/pd/$asin?tag=$_affiliateTag';
  }

  /// Launch Audible affiliate link
  Future<bool> openAudibleLink(UserBook book, {String? asin}) async {
    try {
      String url;
      if (asin != null && asin.isNotEmpty) {
        url = generateDirectAffiliateLink(asin);
      } else {
        url = generateAffiliateLink(book);
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Track affiliate click for analytics
        await _trackAffiliateClick(book, url);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Track affiliate link clicks for revenue analytics
  Future<void> _trackAffiliateClick(UserBook book, String url) async {
    try {
      if (kDisableAnalytics) {
        debugPrint(
          'Analytics disabled via compile-time flag; skipping affiliate tracking for ${book.bookId}',
        );
        return;
      }

      // Check runtime user preference (cached when possible)
      final allowed = await _isAnalyticsAllowedForUser(book.userId);
      if (!allowed) {
        debugPrint(
          'Analytics disabled by user; skipping affiliate tracking for ${book.bookId}',
        );
        return;
      }
      // Log an analytics event to Firebase Analytics
      final analytics = FirebaseAnalytics.instance;
      await analytics.logEvent(
        name: 'audible_affiliate_click',
        parameters: {
          'book_id': book.bookId,
          'book_title': book.title,
          'book_authors': book.authors.join(', '),
          'affiliate_url': url,
          'user_id': book.userId,
          'book_format': book.format.name,
          'has_narrator': book.narrator != null,
        },
      );

      // Persist a lightweight record to Firestore for internal reporting
      try {
        await FirebaseFirestore.instance.collection('affiliate_clicks').add({
          'bookId': book.bookId,
          'bookTitle': book.title,
          'authors': book.authors,
          'affiliateUrl': url,
          'userId': book.userId,
          'bookFormat': book.format.name,
          'hasNarrator': book.narrator != null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Firestore write failures shouldn't block the user flow; log in debug mode.
        debugPrint('affiliate_clicks write failed: $e');
      }

      // Keep a debug log locally as well.
      debugPrint('Affiliate click tracked for book ${book.bookId}');
    } catch (e) {
      // Silently handle tracking errors - don't block user experience
      debugPrint('Failed to track affiliate click: $e');
    }
  }

  /// Public helper to update the local cache when the user toggles analytics
  void setUserAnalyticsEnabled(String userId, bool enabled) {
    if (userId.isEmpty) return;
    _userAnalyticsCache[userId] = enabled;
  }

  /// Public helper for tests and callers to check the runtime preference.
  Future<bool> isAnalyticsAllowedForUser(String? userId) async {
    return await _isAnalyticsAllowedForUser(userId);
  }

  Future<bool> _isAnalyticsAllowedForUser(String? userId) async {
    if (kDisableAnalytics) return false;
    if (userId == null || userId.isEmpty) return true; // default to enabled

    // Allow a runtime override from Firestore: app_config/admin.restrictAnalyticsToOwners
    bool restrict = kRestrictAnalyticsToOwners;
    try {
      final runtime = await _getRuntimeRestrictAnalyticsFlag();
      if (runtime != null) restrict = runtime;
    } catch (_) {
      // ignore and fall back to compile-time config
    }

    // If analytics are restricted to owners, allow only owner UIDs/emails
    if (restrict) {
      // Fast path: UID is in owner list
      if (kOwnerAnalyticsUids.contains(userId)) return true;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final email = doc.data()?['email'] as String? ?? '';
        if (email.isNotEmpty && kOwnerAnalyticsEmails.contains(email)) {
          return true;
        }
      } catch (e) {
        debugPrint(
          'Failed to read user document while checking owner list: $e',
        );
      }
      return false;
    }

    final cached = _userAnalyticsCache[userId];
    if (cached != null) return cached;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final val = doc.data()?['analyticsEnabled'];
      if (val is bool) {
        _userAnalyticsCache[userId] = val;
        return val;
      }
    } catch (e) {
      debugPrint('Failed to read analytics preference for $userId: $e');
    }
    // Default to enabled if not explicitly set or on error
    _userAnalyticsCache[userId] = true;
    return true;
  }

  Future<bool?> _getRuntimeRestrictAnalyticsFlag() async {
    // Return null if no runtime override exists; otherwise return the bool
    if (_runtimeRestrictAnalyticsCache != null) {
      return _runtimeRestrictAnalyticsCache;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('admin')
          .get();
      if (!doc.exists) return null;
      final val = doc.data()?['restrictAnalyticsToOwners'];
      if (val is bool) {
        _runtimeRestrictAnalyticsCache = val;
        return val;
      }
    } catch (e) {
      debugPrint(
        'Failed to read app_config/admin while checking runtime restrict flag: $e',
      );
    }
    return null;
  }

  /// Check if a book should show Audible affiliate link
  bool shouldShowAudibleLink(UserBook book) {
    // Show for all books, but emphasize for audiobooks
    return true;
  }

  /// Get appropriate text for Audible button based on book format
  String getAudibleButtonText(UserBook book) {
    switch (book.format) {
      case BookFormat.audiobook:
        if (book.narrator != null) {
          return 'Listen on Audible';
        } else {
          return 'Get Audiobook';
        }
      default:
        return 'Listen on Audible';
    }
  }

  /// Get icon for Audible button based on book format
  String getAudibleButtonIcon(UserBook book) {
    switch (book.format) {
      case BookFormat.audiobook:
        return 'headphones';
      default:
        return 'headphones';
    }
  }

  /// Generate marketing message for audiobook conversion
  String getAudiobookPrompt(UserBook book) {
    if (book.format == BookFormat.audiobook) {
      if (book.narrator != null) {
        return 'Narrated by ${book.narrator}';
      } else {
        return 'Available as audiobook';
      }
    } else {
      return 'Also available as audiobook';
    }
  }

  /// Calculate potential commission (for internal analytics)
  double calculatePotentialCommission(
    double audiblePrice, {
    double commissionRate = 0.05,
  }) {
    // Audible affiliate commission is typically around 5%
    return audiblePrice * commissionRate;
  }

  /// Get suggested retail price range for audiobooks (for display purposes)
  String getSuggestedPriceRange() {
    return '\$14.95 - \$29.95'; // Typical Audible audiobook price range
  }

  /// Check if user has Audible app installed (mobile-specific)
  Future<bool> hasAudibleApp() async {
    try {
      // Check if Audible app can be opened
      const audibleAppUrl = 'audible://';
      final uri = Uri.parse(audibleAppUrl);
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  /// Open in Audible app if available, otherwise web
  Future<bool> openInAudibleApp(UserBook book, {String? asin}) async {
    try {
      final hasApp = await hasAudibleApp();

      if (hasApp && asin != null) {
        // Try to open in Audible app with deep link
        final appUrl = 'audible://book/$asin';
        final appUri = Uri.parse(appUrl);

        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri);
          await _trackAffiliateClick(book, appUrl);
          return true;
        }
      }

      // Fallback to web affiliate link
      return await openAudibleLink(book, asin: asin);
    } catch (e) {
      // Fallback to web affiliate link
      return await openAudibleLink(book, asin: asin);
    }
  }
}

/// Data class for tracking affiliate performance
class AffiliateClickData {
  final String bookId;
  final String bookTitle;
  final List<String> authors;
  final String userId;
  final DateTime timestamp;
  final String affiliateUrl;
  final BookFormat bookFormat;
  final bool hasNarrator;

  const AffiliateClickData({
    required this.bookId,
    required this.bookTitle,
    required this.authors,
    required this.userId,
    required this.timestamp,
    required this.affiliateUrl,
    required this.bookFormat,
    required this.hasNarrator,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'authors': authors,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'affiliateUrl': affiliateUrl,
      'bookFormat': bookFormat.name,
      'hasNarrator': hasNarrator,
    };
  }

  factory AffiliateClickData.fromJson(Map<String, dynamic> json) {
    return AffiliateClickData(
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String,
      authors: List<String>.from(json['authors'] ?? []),
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      affiliateUrl: json['affiliateUrl'] as String,
      bookFormat: BookFormat.values.byName(json['bookFormat'] as String),
      hasNarrator: json['hasNarrator'] as bool,
    );
  }
}

/// Revenue analytics data for Pro dashboard
class AffiliateRevenueStats {
  final int totalClicks;
  final int totalConversions;
  final double totalRevenue;
  final double conversionRate;
  final Map<BookFormat, int> clicksByFormat;
  final DateTime periodStart;
  final DateTime periodEnd;

  const AffiliateRevenueStats({
    required this.totalClicks,
    required this.totalConversions,
    required this.totalRevenue,
    required this.conversionRate,
    required this.clicksByFormat,
    required this.periodStart,
    required this.periodEnd,
  });

  String get formattedRevenue {
    return '\$${totalRevenue.toStringAsFixed(2)}';
  }

  String get formattedConversionRate {
    return '${(conversionRate * 100).toStringAsFixed(1)}%';
  }
}
