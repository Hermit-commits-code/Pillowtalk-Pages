import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/user_book.dart';
import '../../services/user_library_service.dart';

/// Developer QA screen to quickly exercise core personal-only flows.
class DevQAScreen extends StatefulWidget {
  const DevQAScreen({super.key});

  @override
  State<DevQAScreen> createState() => _DevQAScreenState();
}

class _DevQAScreenState extends State<DevQAScreen> {
  final _logs = <String>[];
  bool _busy = false;

  void _log(Object? o) {
    final line = '${DateTime.now().toIso8601String()} - ${o ?? ''}';
    setState(() => _logs.insert(0, line));
  }

  Future<void> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      _log('Already signed in as ${auth.currentUser!.uid}');
      return;
    }
    _log('Signing in anonymously for QA...');
    final cred = await auth.signInAnonymously();
    _log('Signed in: ${cred.user?.uid}');
  }

  Future<void> _addTestBook() async {
    setState(() => _busy = true);
    try {
      await _ensureSignedIn();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final bookId = 'qa_book_${DateTime.now().millisecondsSinceEpoch}';
      final ub = UserBook(
        id: '${uid}_$bookId',
        userId: uid,
        bookId: bookId,
        title: 'QA Test Book',
        authors: ['QA Tester'],
        status: ReadingStatus.wantToRead,
        genres: ['QA'],
      );
      await UserLibraryService().addBook(ub);
      _log('Added test book ${ub.title}');
    } catch (e) {
      _log('Failed to add test book: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _listLibrary() async {
    setState(() => _busy = true);
    try {
      await _ensureSignedIn();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final list = await UserLibraryService().getUserLibraryStream().first;
      _log('Library (${list.length}) for $uid:');
      for (final b in list) {
        _log(' - ${b.title} (${b.bookId})');
      }
    } catch (e) {
      _log('Failed to list library: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _getTopTropes() async {
    setState(() => _busy = true);
    try {
      await _ensureSignedIn();
      final top = await UserLibraryService().getTopTropesFromLibrary(limit: 20);
      _log('Top tropes (${top.length}): ${top.join(', ')}');
    } catch (e) {
      _log('Failed getTopTropes: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _searchTrope() async {
    setState(() => _busy = true);
    try {
      await _ensureSignedIn();
      final results = await UserLibraryService().searchLibraryByTrope('love');
      _log('Search "love" returned ${results.length} results');
      for (final r in results) {
        _log(' - ${r.title}');
      }
    } catch (e) {
      _log('Failed searchTrope: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('QA only')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dev QA')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _busy ? null : _ensureSignedIn,
                  child: const Text('Ensure Signed In'),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _addTestBook,
                  child: const Text('Add Test Book'),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _listLibrary,
                  child: const Text('List Library'),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _getTopTropes,
                  child: const Text('Get Top Tropes'),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _searchTrope,
                  child: const Text('Search Trope "love"'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, i) => Text(_logs[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
