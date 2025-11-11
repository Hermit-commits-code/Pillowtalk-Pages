# Trope generator tools

This folder contains a small utility to generate `lib/constants/tropes_categorized.dart` from `docs/tropes.md`.

Usage:

```bash
dart run tool/generate_tropes.dart --input docs/tropes.md --output lib/constants/tropes_categorized.dart
```

Options:

- `--input` path to the Markdown file (defaults to `docs/tropes.md`)
- `--output` path to the generated Dart file (defaults to `lib/constants/tropes_categorized.dart`)

The generator deduplicates tropes globally; first occurrence wins. If you prefer multi-category membership, we can extend the generator to support that.
