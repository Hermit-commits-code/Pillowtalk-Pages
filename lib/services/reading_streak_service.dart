// lib/services/reading_streak_service.dart

import '../models/user_book.dart';

class ReadingStreakService {
  /// Calculates the current reading streak (consecutive days with activity)
  /// Activity includes: adding a book, starting a book, or finishing a book
  int calculateCurrentStreak(List<UserBook> books) {
    if (books.isEmpty) return 0;

    // Collect all activity dates
    final Set<DateTime> activityDates = {};

    for (final book in books) {
      if (book.dateAdded != null) {
        activityDates.add(_normalizeDate(book.dateAdded!));
      }
      if (book.dateStarted != null) {
        activityDates.add(_normalizeDate(book.dateStarted!));
      }
      if (book.dateFinished != null) {
        activityDates.add(_normalizeDate(book.dateFinished!));
      }
    }

    if (activityDates.isEmpty) return 0;

    // Sort dates in descending order (most recent first)
    final sortedDates = activityDates.toList()..sort((a, b) => b.compareTo(a));

    final today = _normalizeDate(DateTime.now());

    // Check if there's activity today or yesterday (streak can be alive)
    if (!sortedDates.contains(today) &&
        !sortedDates.contains(today.subtract(const Duration(days: 1)))) {
      return 0; // Streak is broken
    }

    // Count consecutive days backwards from today
    int streak = 0;
    DateTime currentDate = today;

    for (int i = 0; i < sortedDates.length; i++) {
      if (sortedDates.contains(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        // Check if it's just a one-day gap (we allow one missed day)
        final oneDayBefore = currentDate.subtract(const Duration(days: 1));
        if (sortedDates.contains(oneDayBefore)) {
          currentDate = oneDayBefore.subtract(const Duration(days: 1));
          continue; // Skip the gap
        } else {
          break; // Streak is broken
        }
      }
    }

    return streak;
  }

  /// Calculates the longest reading streak ever achieved
  int calculateBestStreak(List<UserBook> books) {
    if (books.isEmpty) return 0;

    // Collect all activity dates
    final Set<DateTime> activityDates = {};

    for (final book in books) {
      if (book.dateAdded != null) {
        activityDates.add(_normalizeDate(book.dateAdded!));
      }
      if (book.dateStarted != null) {
        activityDates.add(_normalizeDate(book.dateStarted!));
      }
      if (book.dateFinished != null) {
        activityDates.add(_normalizeDate(book.dateFinished!));
      }
    }

    if (activityDates.isEmpty) return 0;

    // Sort dates in ascending order
    final sortedDates = activityDates.toList()..sort();

    int currentStreak = 1;
    int maxStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final daysDiff = sortedDates[i].difference(sortedDates[i - 1]).inDays;

      if (daysDiff == 1) {
        // Consecutive day
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else if (daysDiff == 2) {
        // One day gap is allowed
        continue;
      } else {
        // Streak broken
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  /// Normalizes a DateTime to just the date (strips time)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
