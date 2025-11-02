
# Spicy Reads Play Store Policy & Export Compliance Checklist

## Last updated: November 1, 2025

## 1. Google Play Developer Program Policy Compliance

- **App Content:**
  - No sexually explicit images, pornography, or graphic nudity.
  - Romance/erotica book tracking is allowed if content is not explicit in the app UI or screenshots.
  - No hate speech, violence, or discriminatory content.
  - No deceptive, misleading, or impersonation content.
  - No user-generated content that violates Play policies (moderation required if UGC is added).

- **App Description:**
  - Clearly describe the app’s features and intended audience (18+ if romance/erotica is a focus).
  - Avoid misleading claims or superlatives (e.g., “#1 app” unless verifiable).
  - Disclose in-app purchases and subscription terms.
  - Example: “Spicy Reads is a luxury romance book tracker with Pro features, in-app purchases, and exclusive themes. No explicit content is shown in the app.”

- **In-App Purchases:**
  - All IAPs use Google Play Billing.
  - Subscriptions are clearly described and priced.
  - Free trial terms are clear (duration, auto-renewal, cancellation).

- **Privacy & Data:**
  - Privacy policy is linked in the Play Store listing and in-app.
  - User data is not sold or shared without consent.
  - Secure handling of authentication (Firebase Auth) and user data (Firestore).

- **Ads:**
  - If you add ads, they must comply with Google’s ad policies (currently, your app is ad-free for Pro users).

- **Export Compliance:**
  - App does not contain restricted encryption or export-controlled features beyond standard Firebase/Flutter.
  - Add this statement to your Play Store listing and/or app:
    > “This application complies with United States export laws and regulations, including those governing software with encryption. The app is authorized for export from the United States.”

## 2. Export Law Reference

- [Google Play Export Compliance Help](https://support.google.com/googleplay/android-developer/answer/113770?hl=en)
- [U.S. Export Administration Regulations](https://www.bis.doc.gov/index.php/regulations/export-administration-regulations-ear)

## 3. App Description Tips

- Use clear, concise language.
- List key features and Pro benefits.
- Disclose in-app purchases and free trial terms.
- Example description:

> Spicy Reads is your luxury romance book tracker. Organize your library, discover new reads, and unlock exclusive Pro features with a subscription. Enjoy unlimited tracking, advanced analytics, luxury themes, and an ad-free experience. Free trial available. Cancel anytime. No explicit content is shown in the app.

## 4. Final Checklist

- [x] No explicit or policy-violating content in app/screenshots
- [x] In-app purchases and subscriptions use Google Play Billing
- [x] Free trial terms are clear
- [x] Privacy policy is linked
- [x] Export compliance statement included
- [x] App description is clear and policy-compliant

---

_Keep this file up to date as you add features or update your Play Store listing._
