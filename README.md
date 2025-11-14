
# 🌶️ Spicy Reads

Spicy Reads is designed to comply with all [Google Play Developer Program Policies](https://play.google/developer-content-policy/), including but not limited to:

- **Age-Appropriate Content:** The app is intended for adult romance readers (18+), with a mandatory age gate and clear content warnings for mature themes.
- **User Data & Privacy:** We use Firebase for secure authentication and data storage, and comply with GDPR and Google Play privacy requirements. No sensitive personal data is collected or shared without user consent.
- **Intellectual Property:** All book data is sourced from the Google Books API and user-generated content is moderated for compliance.
- **Prohibited Content:** No sexually explicit images, hate speech, or illegal content is permitted. Community moderation and reporting tools are in place.
- **Monetization:** In-app purchases are handled via Google Play Billing and comply with all payment policies.
- **Export Compliance:**
  - This application may be subject to United States export laws. By using or distributing this app, you certify that you comply with all such laws, including any requirements for software with encryption functions. The app is authorized for export from the United States under these laws. [Learn more](https://support.google.com/googleplay/android-developer/answer/113770?hl=en)

For more information, see the [Google Play Developer Policy Center](https://play.google/developer-content-policy/).

## The Ultimate Sanctuary for Romance Readers

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg?style=flat&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28.svg?style=flat&logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-0.1.0-8B0000.svg)](https://github.com/Hermit-commits-code/Pillowtalk-Pages/releases)

> "Romance is not a genre; it's a culture. We are the first book tracker built inside that culture."

## 🌹 Overview

Spicy Reads is a specialized book tracking application designed exclusively for romance readers. Unlike generic book trackers, we understand the unique needs of the romance community - from granular trope categorization to sophisticated spice rating systems.

### 🎯 The Technical MOAT

Our competitive advantage lies in proprietary, community-driven data intelligence:

- **Deep Tropes Engine**: Multi-dimensional search across complex trope combinations
- **Vetted Spice Meter**: Granular rating system with emotional intensity and content warnings
- **Community Metadata**: Crowdsourced, validated data that becomes more valuable with scale

## ✨ Features

### 🔓 Free Tier

- Track up to 50 books
- Basic spice/trope search (1-2 tags)
- Beautiful dark-mode interface
- Reading progress tracking
- Personal reading analytics

### 👑 Pro: The Connoisseur's Club ($19.99/year)

- Unlimited book tracking
- Advanced Deep Tropes Engine (3+ tag combinations)
- Exclusive analytics ("Your Year in Spice")
- Premium themes and customization
- Priority feature access

## 🛠️ Technical Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Frontend** | Flutter 3.0+ | Cross-platform native performance |
| **Backend** | Firebase (Firestore + Auth) | Serverless, scalable database |
| **Book Data** | Google Books API | Comprehensive book metadata |
| **Navigation** | Go Router | Type-safe, declarative routing |
| **State Management** | Provider/Riverpod | Reactive state management |
| **Authentication** | Firebase Auth | Secure user management |

## 🎨 Design Philosophy

**Spicy, Passionate, and Reader-Centric**: Rich, earthy backgrounds with vibrant red and gold accents, inspired by the romance and spice genres.

- **Primary Accent (Heat)** (`#D32F2F`): Classic, strong red for CTAs, high spice ratings, and active states
- **Secondary Accent (Passion)** (`#4527A0`): Deep, luxurious indigo for romance, depth, and sophistication
- **Mild Spice/Highlight** (`#FFB300`): Warm gold/amber for low-spice ratings, progress bars, and highlights
- **Base Text/Dark Mode** (`#263238`): Deep charcoal for primary text and dark backgrounds
- **Background/Light Mode** (`#FFF8E1`): Creamy off-white for main backgrounds in light mode
- **Typography**: Cormorant Garamond for elegant readability

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Firebase CLI
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/Hermit-commits-code/Pillowtalk-Pages.git
   cd Pillowtalk-Pages
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Setup**

   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase for your project
   flutterfire configure
   ```

4. **Run the application**

   ```bash
   flutter run
   ```

### Disable Analytics (development / CI)

To disable analytics globally (for CI or when you don't want telemetry), pass the following flag at build/run time:

```bash
flutter run --dart-define=DISABLE_ANALYTICS=true
```

### Service Account (local tooling)

Development tools may require a Google service account JSON file. Do not commit real credentials to Git. Copy `service-account.json.example` to `service-account.json` locally, or set `GOOGLE_APPLICATION_CREDENTIALS` to point to your credentials file when running tools.

## 📁 Project Structure

```text
lib/
├── config/
│   ├── app_theme.dart          # Custom theme and color palette
│   └── router.dart             # Go Router configuration
├── models/
│   ├── book_model.dart         # RomanceBook data model (MOAT)
│   └── user_book.dart          # User's book tracking model
├── screens/
│   ├── auth/                   # Authentication flows
│   ├── home/                   # Dashboard and main navigation
│   ├── library/                # Personal book collection
│   ├── search/                 # Deep Tropes Engine
│   ├── book/                   # Book details and addition
│   ├── profile/                # User settings and stats
│   └── pro/                    # Subscription management
├── services/
│   └── google_books_service.dart # Google Books API integration
└── main.dart                   # Application entry point
```

## 🔒 Compliance & Legal

### Age Verification (18+ Required)

- **Mandatory Age Gate**: Non-skippable verification on first launch
- **Content Warning**: Clear disclosure of mature themes
- **Legal Compliance**: Meets Google Play 18+ app requirements

### Privacy & Data

- **Firebase Security Rules**: Robust data protection
- **GDPR Compliant**: User data rights respected
- **Amazon Associates**: Proper affiliate disclosure

## 🚀 Development Workflow

### Version Control Strategy

We follow **Semantic Versioning** (SemVer) with phase-based development:

- **Phase 1** (v0.1.x): Project Foundation
- **Phase 2** (v0.2.x): Authentication & Compliance  
- **Phase 3** (v0.3.x): Core Features & MOAT
- **Phase 4** (v0.4.x): Distribution Preparation
- **Production** (v1.0.0+): Play Store Release

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards

- **Linting**: Follow `flutter_lints` rules
- **Testing**: Maintain test coverage above 80%
- **Documentation**: Comment complex business logic
- **Formatting**: Use `dart format` before commits

## 📱 Deployment

### Android (Google Play Store)

```bash
# Build release APK
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (App Store) - Future Release

```bash
# Build iOS release
flutter build ios --release
```

## 📊 Revenue Model

| Metric | Target (Year 1) | Strategy |
|--------|-----------------|----------|
| **Downloads** | 10,000 | Niche marketing to romance communities |
| **Conversion Rate** | 3% | Freemium model with compelling Pro features |
| **Annual Revenue** | $6,950 | Pro subscriptions + Amazon Associates |
| **Retention** | 60%+ | Community-driven MOAT creates stickiness |

## 🤝 Community

- **Target Audience**: Serious romance readers (18+)
- **Primary Platforms**: BookTok, Goodreads, Romance Subreddits
- **Content Strategy**: Spice level discussions, trope analysis
- **User Acquisition**: Word-of-mouth in romance communities

## 📈 Roadmap

### Phase 1: Foundation ✅

- [x] Project setup and dependencies
- [x] Firebase configuration  
- [x] Theme and UI foundation
- [x] Basic navigation structure

### Phase 2: Authentication & Compliance 🚧

- [ ] Splash screen with age verification
- [ ] Login/registration flows
- [ ] Firebase Auth integration
- [ ] Legal compliance implementation

### Phase 3: Core Features 🔮

- [ ] Book search and addition
- [ ] Reading progress tracking
- [ ] Spice Meter implementation
- [ ] Deep Tropes Engine
- [ ] Community ratings system

### Phase 4: Monetization & Launch 🔮

- [ ] Pro subscription integration
- [ ] Amazon Associates setup
- [ ] Play Store optimization
- [ ] Beta testing program

## 🐛 Known Issues

- None currently (v0.1.0 - Foundation phase)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Lead Developer**: [@Hermit-commits-code](https://github.com/Hermit-commits-code)
- **Project Type**: Solo Development
- **Timeline**: Rapid deployment (weeks, not months)

## 📞 Support

- **Documentation**: See [ROADMAP.md](ROADMAP.md) for detailed implementation guide
- **Issues**: [GitHub Issues](https://github.com/Hermit-commits-code/Pillowtalk-Pages/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Hermit-commits-code/Pillowtalk-Pages/discussions)

---

---

---

## Built with 💖 for the Romance Reading Community**

Empowering readers to find their perfect next book through data-driven recommendations

[Download on Google Play](https://play.google.com/store/apps/details?id=com.yourapp.spicyreads) • [View Documentation](ROADMAP.md) • [Join the Community](https://github.com/Hermit-commits-code/Pillowtalk-Pages/discussions)
