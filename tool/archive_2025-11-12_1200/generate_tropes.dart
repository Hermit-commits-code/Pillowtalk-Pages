import 'dart:io';

void main(List<String> args) {
  final argMap = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('--')) {
      final key = a.substring(2);
      final val = (i + 1) < args.length ? args[i + 1] : '';
      if (!val.startsWith('--')) argMap[key] = val;
    }
  }

  final inputPath = argMap['input'] ?? 'docs/tropes.md';
  final outputPath =
      argMap['output'] ?? 'lib/constants/tropes_categorized.dart';
  final checkOnly = argMap.containsKey('check');

  final input = File(inputPath);
  if (!input.existsSync()) {
    stderr.writeln('Input file not found: $inputPath');
    exit(2);
  }

  final lines = input.readAsLinesSync();

  final Map<String, List<String>> categories = {};
  String? current;
  for (var raw in lines) {
    final line = raw.trim();
    if (line.startsWith('## ')) {
      current = line.substring(3).trim();
      categories[current] = [];
      continue;
    }
    if (current == null) continue;
    if (line.startsWith('- ')) {
      var item = line.substring(2).trim();
      if (item.isEmpty) continue;
      // Normalize whitespace
      item = item.replaceAll(RegExp(r"\s+"), ' ').trim();
      // Title-case is avoided to preserve author's casing
      // Avoid duplicates within same category
      if (!categories[current]!.contains(item)) {
        categories[current]!.add(item);
      }
    }
  }

  // Deduplicate globally: first occurrence wins
  final seen = <String>{};
  final Map<String, List<String>> out = {};
  for (final entry in categories.entries) {
    final List<String> kept = [];
    for (final t in entry.value) {
      if (!seen.contains(t)) {
        seen.add(t);
        kept.add(t);
      }
    }
    out[entry.key] = kept;
  }

  final buffer = StringBuffer();
  buffer.writeln("// GENERATED FROM docs/tropes.md");
  buffer.writeln(
    "// Do NOT edit by hand. Run: dart run tool/generate_tropes.dart --input docs/tropes.md --output lib/constants/tropes_categorized.dart",
  );
  buffer.writeln();
  buffer.writeln("const Map<String, List<String>> tropeCategories = {");
  for (final cat in out.keys) {
    buffer.writeln("  '\${_escape(cat)}': [");
    for (final t in out[cat]!) {
      buffer.writeln("    '\${_escape(t)}',");
    }
    buffer.writeln('  ],');
  }
  buffer.writeln('};');
  buffer.writeln();
  buffer.writeln(
    'final List<String> romanceTropesCategorized = tropeCategories.values.expand((l) => l).toList(growable: false);',
  );

  final generated = buffer.toString();

  if (checkOnly) {
    final outFile = File(outputPath);
    if (!outFile.existsSync()) {
      stderr.writeln('Expected generated file not found: $outputPath');
      exit(3);
    }
    final existing = outFile.readAsStringSync();
    if (existing != generated) {
      stderr.writeln(
        'Generated file is out of date. Run the generator to update:',
      );
      stderr.writeln(
        'dart run tool/generate_tropes.dart --input $inputPath --output $outputPath',
      );
      // Print a short diff-like summary: show first differing line.
      final genLines = generated.split('\n');
      final exLines = existing.split('\n');
      final min = genLines.length < exLines.length
          ? genLines.length
          : exLines.length;
      int idx = 0;
      for (; idx < min; idx++) {
        if (genLines[idx] != exLines[idx]) break;
      }
      stderr.writeln('First difference at line ${idx + 1}:');
      stderr.writeln('--- existing');
      stderr.writeln(exLines.length > idx ? exLines[idx] : '<no line>');
      stderr.writeln('+++ generated');
      stderr.writeln(genLines.length > idx ? genLines[idx] : '<no line>');
      exit(4);
    } else {
      stdout.writeln('Generated file is up-to-date.');
      exit(0);
    }
  }

  File(outputPath).writeAsStringSync(generated);
  stdout.writeln('Wrote $outputPath');
}

String _escape(String s) => s.replaceAll("'", "\\'");
