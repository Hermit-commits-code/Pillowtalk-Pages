Analytics in Spicy-Reads

Purpose

This document explains how analytics are handled in the app, how CI disables analytics to avoid sending telemetry from ephemeral runners, and how to run tests against the Firestore emulator.

Key points

- Analytics calls are centralized in `lib/services/analytics_service.dart`.
- Automated builds and test runners should disable analytics by passing a compile-time flag: `DISABLE_ANALYTICS=true`.

How to disable analytics (recommended for CI/tests)

When running tests or other CI tasks, pass the following dart-define to the Flutter tool:

```bash
flutter test --dart-define=DISABLE_ANALYTICS=true
```

This uses a compile-time flag inside `AnalyticsService` (via `bool.fromEnvironment`) to short-circuit logging.

Automated runner notes

- When running tests in automated environments, pass `--dart-define=DISABLE_ANALYTICS=true` to avoid sending telemetry from ephemeral runners.
- If you need to run tests against the Firestore emulator, set `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080` and start the emulator before running tests.

Running tests locally with the emulator

1. Install the Firebase CLI and start the emulator:

```bash
npm install -g firebase-tools
firebase emulators:start --only firestore --project demo-project --host 127.0.0.1 --port 8080
```

2. Export the environment variable so the app/tests connect to the emulator:

```bash
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
```

3. Run tests with analytics disabled (recommended):

```bash
flutter test --dart-define=DISABLE_ANALYTICS=true
```

Notes and best practices

- The app uses `FirebaseAnalytics` only when Firebase is initialized (the analytics wrapper safely catches errors if initialization is missing).
- For unit tests you may prefer `fake_cloud_firestore` (already in `dev_dependencies`) to avoid running the emulator for small fast tests.
- If you need to run CI that actually exercises analytics (rare), remove the `DISABLE_ANALYTICS` dart-define and ensure you have a controlled Firebase project for telemetry.
- For server-side or production analytics injection, consider using a service account and server-side logging pipeline or a separate analytics project to avoid mixing test/dev telemetry with production.

If you want, I can also add a small integration test example that demonstrates using the emulator plus a temporary test project ID and shows how to toggle the RUN_FIREBASE_EMULATOR flag in GitHub Actions.
