// lib/services/reading_analytics_service.dart
import '../models/user_book.dart';

/// Service to calculate reading analytics and statistics for dashboard widgets
class ReadingAnalyticsService {
  static const ReadingAnalyticsService _instance =
      ReadingAnalyticsService._internal();
  factory ReadingAnalyticsService() => _instance;
  const ReadingAnalyticsService._internal();

  /// Calculate comprehensive reading statistics from user's library
  ReadingStats calculateReadingStats(List<UserBook> userBooks) {
    final finishedBooks = userBooks
        .where((book) => book.status == ReadingStatus.finished)
        .toList();
    final currentlyReading = userBooks
        .where((book) => book.status == ReadingStatus.reading)
        .toList();

    return ReadingStats(
      totalBooksRead: finishedBooks.length,
      totalBooksReading: currentlyReading.length,
      totalBooksWantToRead: userBooks
          .where((book) => book.status == ReadingStatus.wantToRead)
          .length,
      averageSpiceRating: _calculateAverageSpice(finishedBooks),
      averagePersonalRating: _calculateAveragePersonalRating(finishedBooks),
      totalPagesRead: _calculateTotalPages(finishedBooks),
      totalAudiobookMinutes: _calculateTotalAudiobookTime(finishedBooks),
      currentStreak: _calculateReadingStreak(finishedBooks),
      favoriteGenres: _calculateTopGenres(finishedBooks, limit: 3),
      topTropes: _calculateTopTropes(finishedBooks, limit: 5),
      monthlyReadingData: _calculateMonthlyData(finishedBooks),
      formatBreakdown: _calculateFormatBreakdown(finishedBooks),
      spiceDistribution: _calculateSpiceDistribution(finishedBooks),
      yearlyGoalProgress: _calculateYearlyProgress(finishedBooks),
    );
  }

  /// Calculate average spice rating from finished books
  double _calculateAverageSpice(List<UserBook> finishedBooks) {
    final booksWithSpice = finishedBooks
        .where((book) => book.spiceOverall != null)
        .toList();
    if (booksWithSpice.isEmpty) return 0.0;

    final totalSpice = booksWithSpice.fold<double>(
      0.0,
      (sum, book) => sum + book.spiceOverall!,
    );
    return totalSpice / booksWithSpice.length;
  }

  /// Calculate average personal rating (1-5 stars)
  double _calculateAveragePersonalRating(List<UserBook> finishedBooks) {
    final ratedBooks = finishedBooks
        .where((book) => book.personalStars != null)
        .toList();
    if (ratedBooks.isEmpty) return 0.0;

    final totalStars = ratedBooks.fold<int>(
      0,
      (sum, book) => sum + book.personalStars!,
    );
    return totalStars / ratedBooks.length;
  }

  /// Calculate total pages read across all finished books
  int _calculateTotalPages(List<UserBook> finishedBooks) {
    return finishedBooks
        .where((book) => book.pageCount != null)
        .fold<int>(0, (sum, book) => sum + book.pageCount!);
  }

  /// Calculate total audiobook listening time in minutes
  int _calculateTotalAudiobookTime(List<UserBook> finishedBooks) {
    return finishedBooks
        .where(
          (book) =>
              book.format == BookFormat.audiobook &&
              book.runtimeMinutes != null,
        )
        .fold<int>(0, (sum, book) => sum + book.runtimeMinutes!);
  }

  /// Calculate current reading streak (consecutive days with finished books)
  int _calculateReadingStreak(List<UserBook> finishedBooks) {
    if (finishedBooks.isEmpty) return 0;

    // Sort books by date finished (most recent first)
    final sortedBooks =
        finishedBooks.where((book) => book.dateFinished != null).toList()
          ..sort((a, b) => b.dateFinished!.compareTo(a.dateFinished!));

    if (sortedBooks.isEmpty) return 0;

    var streak = 0;
    var currentDate = DateTime.now();
    final today = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    // Check if there's a book finished today or within the last 7 days to start streak
    final latestFinish = sortedBooks.first.dateFinished!;
    final latestFinishDay = DateTime(
      latestFinish.year,
      latestFinish.month,
      latestFinish.day,
    );

    if (today.difference(latestFinishDay).inDays > 7) return 0;

    // Count consecutive reading days
    var checkDate = latestFinishDay;
    var bookIndex = 0;

    while (bookIndex < sortedBooks.length) {
      final book = sortedBooks[bookIndex];
      final bookFinishDay = DateTime(
        book.dateFinished!.year,
        book.dateFinished!.month,
        book.dateFinished!.day,
      );

      if (bookFinishDay == checkDate) {
        streak++;
        // Move to previous day and find next book
        checkDate = checkDate.subtract(const Duration(days: 1));
        bookIndex++;

        // Skip books finished on the same day
        while (bookIndex < sortedBooks.length &&
            DateTime(
                  sortedBooks[bookIndex].dateFinished!.year,
                  sortedBooks[bookIndex].dateFinished!.month,
                  sortedBooks[bookIndex].dateFinished!.day,
                ) ==
                bookFinishDay) {
          bookIndex++;
        }
      } else if (bookFinishDay.isBefore(checkDate)) {
        // Gap in reading streak
        break;
      } else {
        bookIndex++;
      }
    }

    return streak;
  }

  /// Calculate top genres by frequency
  List<GenreCount> _calculateTopGenres(
    List<UserBook> finishedBooks, {
    int limit = 3,
  }) {
    final genreFrequency = <String, int>{};

    for (final book in finishedBooks) {
      for (final genre in book.genres) {
        genreFrequency[genre] = (genreFrequency[genre] ?? 0) + 1;
      }
    }

    final sortedGenres =
        genreFrequency.entries
            .map((entry) => GenreCount(genre: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return sortedGenres.take(limit).toList();
  }

  /// Calculate top tropes by frequency
  List<TropeCount> _calculateTopTropes(
    List<UserBook> finishedBooks, {
    int limit = 5,
  }) {
    final tropeFrequency = <String, int>{};

    for (final book in finishedBooks) {
      for (final trope in book.userSelectedTropes) {
        tropeFrequency[trope] = (tropeFrequency[trope] ?? 0) + 1;
      }
    }

    final sortedTropes =
        tropeFrequency.entries
            .map((entry) => TropeCount(trope: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return sortedTropes.take(limit).toList();
  }

  /// Calculate monthly reading data for charts
  List<MonthlyReadingData> _calculateMonthlyData(List<UserBook> finishedBooks) {
    final monthlyData = <String, MonthlyReadingData>{};
    final now = DateTime.now();

    // Initialize last 12 months
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyData[key] = MonthlyReadingData(
        month: key,
        booksFinished: 0,
        pagesRead: 0,
        averageSpice: 0.0,
      );
    }

    // Populate with actual data
    for (final book in finishedBooks) {
      if (book.dateFinished == null) continue;

      final finishDate = book.dateFinished!;
      final key =
          '${finishDate.year}-${finishDate.month.toString().padLeft(2, '0')}';

      if (monthlyData.containsKey(key)) {
        final existing = monthlyData[key]!;
        monthlyData[key] = MonthlyReadingData(
          month: key,
          booksFinished: existing.booksFinished + 1,
          pagesRead: existing.pagesRead + (book.pageCount ?? 0),
          averageSpice: existing.averageSpice, // Will recalculate after
        );
      }
    }

    // Recalculate average spice for each month
    for (final key in monthlyData.keys) {
      final monthBooks = finishedBooks.where((book) {
        if (book.dateFinished == null) return false;
        final finishDate = book.dateFinished!;
        final bookKey =
            '${finishDate.year}-${finishDate.month.toString().padLeft(2, '0')}';
        return bookKey == key;
      }).toList();

      if (monthBooks.isNotEmpty) {
        final spiceBooks = monthBooks
            .where((book) => book.spiceOverall != null)
            .toList();
        if (spiceBooks.isNotEmpty) {
          final avgSpice =
              spiceBooks.fold<double>(
                0.0,
                (sum, book) => sum + book.spiceOverall!,
              ) /
              spiceBooks.length;
          monthlyData[key] = monthlyData[key]!.copyWith(averageSpice: avgSpice);
        }
      }
    }

    return monthlyData.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month));
  }

  /// Calculate format breakdown (physical vs digital vs audiobook)
  Map<BookFormat, int> _calculateFormatBreakdown(List<UserBook> finishedBooks) {
    final formatCounts = <BookFormat, int>{};

    for (final format in BookFormat.values) {
      formatCounts[format] = 0;
    }

    for (final book in finishedBooks) {
      formatCounts[book.format] = formatCounts[book.format]! + 1;
    }

    return formatCounts;
  }

  /// Calculate spice rating distribution
  Map<String, int> _calculateSpiceDistribution(List<UserBook> finishedBooks) {
    final spiceDistribution = <String, int>{
      'Mild (1-2)': 0,
      'Medium (2-3)': 0,
      'Hot (3-4)': 0,
      'Scorching (4-5)': 0,
      'Unrated': 0,
    };

    for (final book in finishedBooks) {
      if (book.spiceOverall == null) {
        spiceDistribution['Unrated'] = spiceDistribution['Unrated']! + 1;
      } else {
        final spice = book.spiceOverall!;
        if (spice < 2.0) {
          spiceDistribution['Mild (1-2)'] =
              spiceDistribution['Mild (1-2)']! + 1;
        } else if (spice < 3.0) {
          spiceDistribution['Medium (2-3)'] =
              spiceDistribution['Medium (2-3)']! + 1;
        } else if (spice < 4.0) {
          spiceDistribution['Hot (3-4)'] = spiceDistribution['Hot (3-4)']! + 1;
        } else {
          spiceDistribution['Scorching (4-5)'] =
              spiceDistribution['Scorching (4-5)']! + 1;
        }
      }
    }

    return spiceDistribution;
  }

  /// Calculate yearly reading goal progress
  YearlyGoalProgress _calculateYearlyProgress(List<UserBook> finishedBooks) {
    final currentYear = DateTime.now().year;
    final yearlyFinished = finishedBooks
        .where((book) => book.dateFinished?.year == currentYear)
        .length;

    // Default goal of 52 books per year (1 per week)
    const defaultYearlyGoal = 52;
    final progress = yearlyFinished / defaultYearlyGoal;

    return YearlyGoalProgress(
      goal: defaultYearlyGoal,
      completed: yearlyFinished,
      progress: progress.clamp(0.0, 1.0),
      isOnTrack: _isOnTrackForYearlyGoal(yearlyFinished, defaultYearlyGoal),
    );
  }

  /// Check if user is on track for yearly reading goal
  bool _isOnTrackForYearlyGoal(int booksRead, int yearlyGoal) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final daysInYear = DateTime(
      now.year + 1,
      1,
      1,
    ).difference(DateTime(now.year, 1, 1)).inDays;

    final expectedProgress = (dayOfYear / daysInYear) * yearlyGoal;
    return booksRead >= expectedProgress;
  }
}

/// Comprehensive reading statistics data class
class ReadingStats {
  final int totalBooksRead;
  final int totalBooksReading;
  final int totalBooksWantToRead;
  final double averageSpiceRating;
  final double averagePersonalRating;
  final int totalPagesRead;
  final int totalAudiobookMinutes;
  final int currentStreak;
  final List<GenreCount> favoriteGenres;
  final List<TropeCount> topTropes;
  final List<MonthlyReadingData> monthlyReadingData;
  final Map<BookFormat, int> formatBreakdown;
  final Map<String, int> spiceDistribution;
  final YearlyGoalProgress yearlyGoalProgress;

  const ReadingStats({
    required this.totalBooksRead,
    required this.totalBooksReading,
    required this.totalBooksWantToRead,
    required this.averageSpiceRating,
    required this.averagePersonalRating,
    required this.totalPagesRead,
    required this.totalAudiobookMinutes,
    required this.currentStreak,
    required this.favoriteGenres,
    required this.topTropes,
    required this.monthlyReadingData,
    required this.formatBreakdown,
    required this.spiceDistribution,
    required this.yearlyGoalProgress,
  });

  /// Format audiobook time as human readable
  String get formattedAudiobookTime {
    final hours = totalAudiobookMinutes ~/ 60;
    final minutes = totalAudiobookMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Format total pages with commas
  String get formattedTotalPages {
    return totalPagesRead.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }
}

/// Genre count data class
class GenreCount {
  final String genre;
  final int count;

  const GenreCount({required this.genre, required this.count});
}

/// Trope count data class
class TropeCount {
  final String trope;
  final int count;

  const TropeCount({required this.trope, required this.count});
}

/// Monthly reading data for charts
class MonthlyReadingData {
  final String month;
  final int booksFinished;
  final int pagesRead;
  final double averageSpice;

  const MonthlyReadingData({
    required this.month,
    required this.booksFinished,
    required this.pagesRead,
    required this.averageSpice,
  });

  MonthlyReadingData copyWith({
    String? month,
    int? booksFinished,
    int? pagesRead,
    double? averageSpice,
  }) {
    return MonthlyReadingData(
      month: month ?? this.month,
      booksFinished: booksFinished ?? this.booksFinished,
      pagesRead: pagesRead ?? this.pagesRead,
      averageSpice: averageSpice ?? this.averageSpice,
    );
  }
}

/// Yearly goal progress tracking
class YearlyGoalProgress {
  final int goal;
  final int completed;
  final double progress;
  final bool isOnTrack;

  const YearlyGoalProgress({
    required this.goal,
    required this.completed,
    required this.progress,
    required this.isOnTrack,
  });

  int get remaining => goal - completed;
  double get progressPercentage => progress * 100;
}
