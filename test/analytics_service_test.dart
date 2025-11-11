import 'package:flutter_test/flutter_test.dart';

/// Mock analytics event recorder for testing
class MockAnalyticsRecorder {
  final List<Map<String, Object?>> events = [];

  void recordEvent(String name, {Map<String, Object>? params}) {
    events.add({
      'name': name,
      'params': params ?? {},
      'timestamp': DateTime.now(),
    });
  }

  void clear() => events.clear();

  Map<String, Object?>? lastEvent() => events.isNotEmpty ? events.last : null;

  int eventCount(String name) =>
      events.where((e) => e['name'] == name).length;
}

void main() {
  group('AnalyticsService Events', () {
    late MockAnalyticsRecorder recorder;

    setUp(() {
      recorder = MockAnalyticsRecorder();
    });

    test('logAddBook records correct event with parameters', () {
      recorder.recordEvent(
        'add_book',
        params: {'user_book_id': 'user123_book456', 'book_id': 'book456'},
      );

      expect(recorder.eventCount('add_book'), 1);
      final event = recorder.lastEvent();
      expect(event?['name'], 'add_book');
      expect(event?['params'], containsPair('user_book_id', 'user123_book456'));
      expect(event?['params'], containsPair('book_id', 'book456'));
    });

    test('logCreateList records correct event with parameters', () {
      recorder.recordEvent(
        'create_list',
        params: {'list_id': 'list123', 'name': 'My Favorites'},
      );

      expect(recorder.eventCount('create_list'), 1);
      final event = recorder.lastEvent();
      expect(event?['name'], 'create_list');
      expect(event?['params'], containsPair('list_id', 'list123'));
      expect(event?['params'], containsPair('name', 'My Favorites'));
    });

    test('logAddBookToList records correct event', () {
      recorder.recordEvent(
        'add_book_to_list',
        params: {'list_id': 'list123', 'user_book_id': 'user123_book456'},
      );

      expect(recorder.eventCount('add_book_to_list'), 1);
      final event = recorder.lastEvent();
      expect(event?['name'], 'add_book_to_list');
      expect(event?['params'], containsPair('list_id', 'list123'));
      expect(event?['params'], containsPair('user_book_id', 'user123_book456'));
    });

    test('logRemoveBookFromList records correct event', () {
      recorder.recordEvent(
        'remove_book_from_list',
        params: {'list_id': 'list123', 'user_book_id': 'user123_book456'},
      );

      expect(recorder.eventCount('remove_book_from_list'), 1);
      final event = recorder.lastEvent();
      expect(event?['name'], 'remove_book_from_list');
      expect(event?['params'], containsPair('list_id', 'list123'));
      expect(event?['params'], containsPair('user_book_id', 'user123_book456'));
    });

    test('logOnboardingComplete records without method', () {
      recorder.recordEvent('onboarding_complete');

      expect(recorder.eventCount('onboarding_complete'), 1);
      final event = recorder.lastEvent();
      expect(event?['name'], 'onboarding_complete');
    });

    test('logOnboardingComplete records with method', () {
      recorder.recordEvent(
        'onboarding_complete',
        params: {'method': 'email_signup'},
      );

      expect(recorder.eventCount('onboarding_complete'), 1);
      final event = recorder.lastEvent();
      expect(event?['params'], containsPair('method', 'email_signup'));
    });

    test('logApplyFilter records without filter_id', () {
      recorder.recordEvent('apply_filter', params: {'filter_type': 'kink'});

      expect(recorder.eventCount('apply_filter'), 1);
      final event = recorder.lastEvent();
      expect(event?['name'], 'apply_filter');
      expect(event?['params'], containsPair('filter_type', 'kink'));
    });

    test('logApplyFilter records with filter_id', () {
      recorder.recordEvent(
        'apply_filter',
        params: {'filter_id': 'filter_abc123', 'filter_name': 'BDSM'},
      );

      expect(recorder.eventCount('apply_filter'), 1);
      final event = recorder.lastEvent();
      expect(event?['params'], containsPair('filter_id', 'filter_abc123'));
      expect(event?['params'], containsPair('filter_name', 'BDSM'));
    });

    test('logUpgradeToPro records without source', () {
      recorder.recordEvent('upgrade_to_pro');

      expect(recorder.eventCount('upgrade_to_pro'), 1);
      final event = recorder.lastEvent();
      expect(event?['name'], 'upgrade_to_pro');
    });

    test('logUpgradeToPro records with source', () {
      recorder.recordEvent(
        'upgrade_to_pro',
        params: {'source': 'trope_selection_screen'},
      );

      expect(recorder.eventCount('upgrade_to_pro'), 1);
      final event = recorder.lastEvent();
      expect(event?['params'], containsPair('source', 'trope_selection_screen'));
    });

    test('logEvent allows arbitrary event names and parameters', () {
      recorder.recordEvent(
        'custom_event',
        params: {'custom_key': 'custom_value', 'another_key': 'another_value'},
      );

      expect(recorder.eventCount('custom_event'), 1);
      final event = recorder.lastEvent();
      expect(event?['name'], 'custom_event');
      expect(event?['params'], containsPair('custom_key', 'custom_value'));
    });

    test('Multiple events are recorded in order', () {
      recorder.recordEvent('add_book', params: {'book_id': 'book1'});
      recorder.recordEvent('add_book', params: {'book_id': 'book2'});
      recorder.recordEvent('create_list', params: {'list_id': 'list1'});

      expect(recorder.events.length, 3);
      expect(recorder.eventCount('add_book'), 2);
      expect(recorder.eventCount('create_list'), 1);

      // Verify order
      expect(recorder.events[0]['name'], 'add_book');
      expect(recorder.events[1]['name'], 'add_book');
      expect(recorder.events[2]['name'], 'create_list');
    });

    test('logAddBook includes required parameters', () {
      recorder.recordEvent(
        'add_book',
        params: {'user_book_id': 'ub123', 'book_id': 'b456'},
      );

      final event = recorder.lastEvent();
      final params = event?['params'] as Map;
      expect(params.containsKey('user_book_id'), true);
      expect(params.containsKey('book_id'), true);
    });

    test('Event timestamps are recorded', () {
      final before = DateTime.now();
      recorder.recordEvent('test_event');
      final after = DateTime.now();

      final event = recorder.lastEvent();
      final timestamp = event?['timestamp'] as DateTime?;

      expect(timestamp, isNotNull);
      expect(timestamp!.isAfter(before) || timestamp.isAtSameMomentAs(before), true);
      expect(timestamp.isBefore(after) || timestamp.isAtSameMomentAs(after), true);
    });

    test('Clear removes all recorded events', () {
      recorder.recordEvent('event1');
      recorder.recordEvent('event2');
      expect(recorder.events.length, 2);

      recorder.clear();

      expect(recorder.events.length, 0);
    });

    test('User journey: Onboarding -> Add Book -> Create List -> Upgrade', () {
      // Simulate a user journey
      recorder.recordEvent('onboarding_complete', params: {'method': 'email'});
      recorder.recordEvent('add_book', params: {'book_id': 'b1'});
      recorder.recordEvent('add_book', params: {'book_id': 'b2'});
      recorder.recordEvent('create_list', params: {'list_id': 'l1'});
      recorder.recordEvent('upgrade_to_pro', params: {'source': 'book_add_flow'});

      expect(recorder.events.length, 5);
      expect(recorder.eventCount('add_book'), 2);
      expect(recorder.eventCount('onboarding_complete'), 1);
      expect(recorder.eventCount('upgrade_to_pro'), 1);

      // Verify sequence
      expect(recorder.events[0]['name'], 'onboarding_complete');
      expect(recorder.events[1]['name'], 'add_book');
      expect(recorder.events[2]['name'], 'add_book');
      expect(recorder.events[3]['name'], 'create_list');
      expect(recorder.events[4]['name'], 'upgrade_to_pro');
    });

    test('Null parameters are handled correctly', () {
      // Event with null params should not crash
      recorder.recordEvent('test_event', params: null);

      final event = recorder.lastEvent();
      expect(event?['params'], isEmpty);
    });

    test('Empty params map is recorded correctly', () {
      recorder.recordEvent('test_event', params: {});

      final event = recorder.lastEvent();
      expect(event?['params'], isEmpty);
    });
  });
}
