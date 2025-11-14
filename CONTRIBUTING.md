# Contributing

We follow a lightweight process to keep contributions focused and reviewable.

Commit messages
- Use Conventional Commits format. Examples:
  - `feat(book): add audible affiliate button`
  - `fix(profile): persist analytics toggle to Firestore`
  - `chore(release): bump version to v1.1.0`

Pull requests
- Create small, single-purpose PRs.
- Include a short description and screenshots for UI changes.
- Link tests and CI passing status.

Release process
- Bump `pubspec.yaml` version with a PR, update `CHANGELOG.md`, create an annotated tag `vX.Y.Z`, and push to `main`.
