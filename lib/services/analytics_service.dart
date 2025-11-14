import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Simple analytics wrapper to centralize event names and calls.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  // When running CI or tests you may want to disable analytics to avoid
  // sending telemetry from ephemeral workers. Set with --dart-define.
  static final bool _analyticsDisabled = bool.fromEnvironment(
    'DISABLE_ANALYTICS',
    defaultValue: false,
  );

  /// Internal helper to safely call FirebaseAnalytics without throwing
  /// when a Firebase app hasn't been initialized (e.g., in unit tests).
  Future<void> _safeLog(String name, {Map<String, Object>? params}) async {
    if (_analyticsDisabled) {
      if (kDebugMode) {
        debugPrint('Analytics disabled via DISABLE_ANALYTICS; skipping $name');
      }
      return;
    }

    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Analytics _safeLog failed: $e');
      }
    }
  }

  Future<void> logAddBook({
    required String userBookId,
    required String bookId,
  }) async {
    await _safeLog(
      'add_book',
      params: {'user_book_id': userBookId, 'book_id': bookId},
    );
  }

  Future<void> logCreateList({
    required String listId,
    required String name,
  }) async {
    await _safeLog('create_list', params: {'list_id': listId, 'name': name});
  }

  Future<void> logAddBookToList({
    required String listId,
    required String userBookId,
  }) async {
    await _safeLog(
      'add_book_to_list',
      params: {'list_id': listId, 'user_book_id': userBookId},
    );
  }

  Future<void> logRemoveBookFromList({
    required String listId,
    required String userBookId,
  }) async {
    await _safeLog(
      'remove_book_from_list',
      params: {'list_id': listId, 'user_book_id': userBookId},
    );
  }

  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    await _safeLog(name, params: params);
  }

  // Higher-level events used across the app
  Future<void> logOnboardingComplete({String? method}) async {
    await _safeLog(
      'onboarding_complete',
      params: method != null ? {'method': method} : null,
    );
  }

  Future<void> logApplyFilter({
    String? filterId,
    Map<String, Object>? details,
  }) async {
    final params = <String, Object>{};
    if (filterId != null) params['filter_id'] = filterId;
    if (details != null) params.addAll(details);
    await _safeLog('apply_filter', params: params.isEmpty ? null : params);
  }

  Future<void> logUpgradeToPro({String? source}) async {
    await _safeLog(
      'upgrade_to_pro',
      params: source != null ? {'source': source} : null,
    );
  }
}
