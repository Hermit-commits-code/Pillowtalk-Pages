// Helper utilities for content warning / hard-stop overlap detection
List<String> findWarningOverlap(
  List<String>? bookWarnings,
  List<String>? userStops, [
  List<String>? ignoredWarnings,
]) {
  if (bookWarnings == null || userStops == null) return <String>[];

  final normalizedStops = userStops.map((s) => s.toLowerCase().trim()).toSet();
  final normalizedIgnored = (ignoredWarnings ?? [])
      .map((s) => s.toLowerCase().trim())
      .toSet();

  final matches = <String>[];
  for (final w in bookWarnings) {
    final n = w.toLowerCase().trim();
    if (normalizedStops.contains(n) && !normalizedIgnored.contains(n)) {
      matches.add(w);
    }
  }

  return matches;
}
