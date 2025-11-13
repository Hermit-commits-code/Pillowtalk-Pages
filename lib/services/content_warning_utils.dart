// Helper utilities for content warning / hard-stop overlap detection
List<String> findWarningOverlap(List<String>? bookWarnings, List<String>? userStops) {
  if (bookWarnings == null || userStops == null) return <String>[];

  final normalizedStops = userStops.map((s) => s.toLowerCase().trim()).toSet();

  final matches = <String>[];
  for (final w in bookWarnings) {
    final n = w.toLowerCase().trim();
    if (normalizedStops.contains(n)) matches.add(w);
  }

  return matches;
}
