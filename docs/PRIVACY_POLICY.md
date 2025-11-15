# Privacy Policy for Spicy Reads

Last updated: 2025-11-03

This Privacy Policy describes how Spicy Reads (the "App"), developed by the project maintainers, collects, uses, and shares information from users.

1. Information We Collect

- Account information: If you create an account we collect email address and display name (via Firebase Authentication).
- Profile and library data: Books you add, reading progress, preferences, and user-generated tags/ratings are stored in Firestore under your user document.
- Device and diagnostic data: We collect limited diagnostic information to improve app stability and performance.
- Third-party services: We use Firebase services (Auth, Cloud Firestore, Crashlytics, Analytics) and the Google Books API.

2. How We Use Information

- Provide and maintain the App's features (syncing library, preferences, and user data).
- Authenticate users and secure access to private data.
- Improve the App through analytics and crash reporting.
- Send transactional messages related to your account (e.g., password resets) via Firebase Auth.

3. Data Sharing and Disclosure

- We do not sell or rent your personal data.
- We share data with service providers only as necessary to operate the App (e.g., Firebase, Google Books API). These providers are contractually required to protect your data.
- Aggregate or anonymized analytics data may be used for product improvement.

4. Data Retention

We retain user data as long as the account exists or as required to provide the service. You can request deletion of your account and associated data by contacting the support address below.

5. Security

We use Firebase security rules and authenticated access to protect user data. No system is perfectly secure; we follow best practices to minimize risks.

6. Your Choices

- You can delete your account to remove your personal data from our servers.
- You can manage in-app preferences (e.g., filters, theme) via the Profile screen.

### Analytics and Affiliate Tracking

- We use Firebase Analytics to collect anonymous, aggregate usage information to improve the App. This includes events such as feature usage and affiliate link clicks.
- Affiliate link clicks (for example Audible/Amazon links) are recorded as lightweight, non-sensitive records in a Firestore collection named `affiliate_clicks`. Records include the referenced book ID, a timestamp, and the affiliate URL. These records are used only for internal reporting and revenue tracking; they are not sold or shared.
- You can opt out of analytics and affiliate tracking at any time via the Profile → Settings → "Allow analytics & affiliate tracking" toggle. When disabled, analytics events and affiliate click records will not be sent for your user account. Developers may also disable analytics at build time via the `--dart-define=DISABLE_ANALYTICS=true` flag.

### Service Account Files

- Development tools may require a Google service account JSON file. Never commit real service account JSON files to source control. Use the provided `service-account.json.example` as a template and set your credentials via the `GOOGLE_APPLICATION_CREDENTIALS` environment variable during tooling runs.

7. Children

The App is intended for users 18 years or older. We do not knowingly collect information from children under 18.

8. Contact

For questions or requests regarding this policy, contact: support@yourdomain.com

---

_This privacy policy is a template. Before publishing, review it for accuracy and add your real support contact and hosting details._
