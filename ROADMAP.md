# 💖 Pillowtalk Pages: The Ultimate Sanctuary Implementation Roadmap

**The Vein of Truth:** "Romance is not a genre; it's a culture. We are the first book tracker built *inside* that culture."

---

## 🛠️ I. Strategic Foundation: Technical MOAT & Competitive Edge

### 1.A. The Core Philosophy (The Vein of Truth)

**Strategic Imperative:** Hyper-specialization to solve the romance reader's primary pain point: predictive content filtering based on granular, emotionally resonant criteria.

**The Technical MOAT Components:**

| Component | Description | Competitive Advantage |
|-----------|-------------|----------------------|
| **Deep Tropes Engine** | Multi-select search for complex combinations (e.g., "Enemies to Lovers AND Grumpy Sunshine AND Mutual Pining") | Goes beyond basic tags, serving specific search patterns of romance community |
| **Vetted Spice Meter** | 0-5 Flames rating with mandatory sub-categories: Emotional Intensity, On-Page Sex, Content Warnings | The standard for vetting books, replacing generic competitors |
| **Community-Driven Data** | Proprietary, validated metadata schema populated by gamified user contributions | Structurally insurmountable for generalist competitors |

### 1.B. Framework Decision Matrix

| Framework | Pros | Cons | Verdict |
|-----------|------|------|---------|
| **Kotlin (Native)** | Best performance, true native look/feel | Android-only, highest learning curve, slowest to build | **REJECT**: Too slow and limited for rapid launch |
| **React PWA** | Web-first, easy updates | Less native feel, custom UI/animations are cumbersome | **REJECT**: Aesthetic risk too high |
| **Flutter** ✅ | Single codebase (Android/iOS/Web), excellent for custom UI, strong performance | Larger app size, slight learning curve | **CHOSEN**: Best blend of speed, aesthetics, cross-platform |

### 1.C. Technical Stack Blueprint

| Feature | Technology | Rationale | Required Packages |
|---------|------------|-----------|-------------------|
| **Backend & Database** | Firebase (Firestore & Auth) | Free tier, serverless, zero maintenance cost | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| **Book Data** | Google Books API (REST) | Free metadata (Title, Author, ISBN, Cover) | `dio` or `http` |
| **Navigation** | Go Router | Modern declarative routing | `go_router` |
| **Local Storage** | Shared Preferences | Age gate flag storage | `shared_preferences` |
| **External Links** | URL Launcher | Amazon Associates links | `url_launcher` |
| **Monetization** | In-App Purchase | Pro subscription handling | `in_app_purchase` |

---

## 🎨 II. The Sensual Aesthetic & Color Palette

**Design Strategy:** Dark mode focus, exclusive, luxurious, and intimate feel.

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| **Primary Rose** | `0xFF8B0000` | Main accent, primary action buttons, branding |
| **Secondary Gold** | `0xFFFFD700` | Highlights, Spice Meter flames, Pro feature call-outs |
| **Background Midnight** | `0xFF0F0F0F` | Main background, depth, and luxury |
| **Card Dark** | `0xFF1A1A1A` | Separating cards and list items |
| **Text Soft White** | `0xFFF5F5F5` | Primary text for readability |

---

## 💰 III. Monetization & Revenue Strategy

### 3.A. Pricing Tiers

| Tier | Feature Access | Value Proposition | Price |
|------|----------------|-------------------|-------|
| **Free (Default)** | Track up to 50 books, Basic Spice/Trope search (1-2 tags), Core reading log | Full functionality for casual readers | **$0.00** |
| **Pro: The Connoisseur's Club** | Unlimited tracking, Full Deep Tropes Engine (3+ tag combinations), Advanced analytics, Exclusive themes, Ad-free | Essential for serious romance readers | **Annual: $19.99** / Monthly: $2.99 |

### 3.B. Conservative Year 1 Revenue Projection

- **Target Users (Installs):** 10,000
- **Conversion Rate (Free → Paid):** 3%
- **Paid Users:** 300
- **Projected Gross Revenue:** ~$6,950 (before Google's 15% cut)

### 3.C. Secondary Revenue: Amazon Associates

- **Mechanism:** Prominent "Buy on Amazon" button on book detail pages
- **Required Disclosure:** "Pillowtalk Pages is a participant in the Amazon Services LLC Associates Program"

---

## ⚖️ IV. Legal & Compliance Requirements (18+ App)

### 4.A. Mandatory Age Gate Implementation

**Critical:** Non-skippable 18+ verification on first launch.

**Required Elements:**

- Clear warning about mature content including sexual themes
- Non-dismissible dialog
- "Under 18" option that exits the app
- "18 or older" option that stores verification flag

### 4.B. Google Play Console Compliance Checklist

| Compliance Step | Action Required | Console Section |
|-----------------|-----------------|-----------------|
| **Content Rating** | Declare sexual content and user-generated content for Mature (17+) rating | App Content → Content Rating |
| **Target Audience** | Select 18 and over | App Content → Target audience |
| **App Access** | Provide test credentials for reviewer access | App Content → App Access |
| **Privacy Policy** | Host public URL detailing data collection | App Content → Privacy Policy |
| **Amazon Disclosure** | Visible affiliate disclosure in app | Store Listing and In-App UI |

---

## � Git Version Control & Semantic Versioning Strategy

### Versioning Convention

We'll follow **Semantic Versioning (SemVer)** with the format: `MAJOR.MINOR.PATCH`

- **MAJOR** version: Incompatible API changes (1.0.0, 2.0.0)
- **MINOR** version: New functionality in backward-compatible manner (1.1.0, 1.2.0)
- **PATCH** version: Backward-compatible bug fixes (1.1.1, 1.1.2)

### Phase-Based Versioning Plan

| Phase | Version Range | Description |
|-------|---------------|-------------|
| **Phase 1** | 0.1.0 - 0.1.x | Project setup, Firebase, Theme |
| **Phase 2** | 0.2.0 - 0.2.x | Authentication & Compliance |
| **Phase 3** | 0.3.0 - 0.3.x | Core features & MOAT |
| **Phase 4** | 0.4.0 - 0.4.x | Distribution prep |
| **Production** | 1.0.0+ | Play Store release |

### Git Workflow for Each Step

After completing each step (1.1, 1.2, etc.), execute:

```bash
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "feat: [step description] - v[version]"

# Tag the version
git tag v[version]

# Push commits and tags
git push origin main
git push origin --tags
```

---

## �🚀 V. Hyper-Detailed Step-by-Step Implementation

### Phase 1: Project Initialization & Core Framework

#### Step 1.1: Create Project & Define Dependencies

**Command Line: Create Flutter Project**

```bash
flutter create pillowtalk_pages
cd pillowtalk_pages
```

**Edit pubspec.yaml: Add Core Dependencies**

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  
  # Utility & Navigation
  shared_preferences: ^2.2.2
  url_launcher: ^6.2.2
  go_router: ^12.1.3
  
  # API/Network & Monetization
  dio: ^5.4.0
  in_app_purchase: ^3.1.11
  
  # UI Enhancements
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

**Command Line: Fetch Packages**

```bash
flutter pub get
```

**🔄 Version Control: Complete Step 1.1**

```bash
# Initialize Git repository (if not already done)
git init
git branch -M main

# Stage all changes
git add .

# Commit with descriptive message
git commit -m "feat: project setup and dependencies - v0.1.0

- Created Flutter project structure
- Added core dependencies (Firebase, Navigation, UI)
- Configured pubspec.yaml with required packages"

# Tag the version
git tag v0.1.0

# Push to remote (set up remote first if needed)
# git remote add origin https://github.com/yourusername/pillowtalk_pages.git
# git push -u origin main
# git push origin --tags
```

#### Step 1.2: Firebase Project Setup

**Firebase Console Actions:**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project" → Name: "Pillowtalk Pages"
3. Disable Google Analytics (zero-dollar budget focus)

**CLI Configuration:**

```bash
# Install FlutterFire CLI (if not already installed)
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Flutter project with Firebase
flutterfire configure
```

**Firebase Console: Enable Services**

1. **Authentication:**
   - Go to Build → Authentication → Get started
   - Sign-in method → Enable Email/Password and Google

2. **Firestore Database:**
   - Go to Build → Firestore Database → Create database
   - Choose production mode
   - Select region (preferably US-central for performance)

**🔄 Version Control: Complete Step 1.2**

```bash
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "feat: Firebase project setup and configuration - v0.1.1

- Configured Firebase project in console
- Added FlutterFire CLI configuration
- Enabled Authentication and Firestore services
- Generated firebase_options.dart"

# Tag the version
git tag v0.1.1

# Push commits and tags
git push origin main
git push origin --tags
```

#### Step 1.3: Firestore Security Rules (Critical MOAT Protection)

**Firebase Console: Database → Rules**

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User-specific data
    match /users/{userId} {
      allow read, update, delete: if request.auth.uid == userId;
      allow create: if request.auth.uid != null;
    }

    // The proprietary MOAT data collection
    match /books/{bookId} {
      // Allow read access to everyone (essential for search)
      allow read: if true; 
      // Allow write only if authenticated
      allow create, update: if request.auth.uid != null; 
    }

    // User-submitted ratings (contributes to MOAT)
    match /ratings/{ratingId} {
      // Users can only submit/edit their own ratings
      allow read, write: if request.auth.uid != null 
        && ratingId.matches('^' + request.auth.uid + '_.*');
    }
  }
}
```

**🔄 Version Control: Complete Step 1.3**

```bash
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "feat: Firestore security rules for MOAT protection - v0.1.2

- Implemented Firestore security rules
- Protected user-specific data collections
- Enabled public read access for books collection
- Secured ratings collection with user ownership"

# Tag the version
git tag v0.1.3

# Push commits and tags
git push origin main
git push origin --tags
```

#### Step 1.4: Define The Sensual Theme

**Create lib/config/app_theme.dart**

```dart
// lib/config/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// The Pillowtalk Pages Palette: Deep, Luxurious, and Warm
const Color primaryRose = Color(0xFF8B0000);     // Deep Rose/Maroon
const Color secondaryGold = Color(0xFFFFD700);   // Gold Accent
const Color backgroundMidnight = Color(0xFF0F0F0F); // Near-Black
const Color cardDark = Color(0xFF1A1A1A);        // Card Background
const Color textSoftWhite = Color(0xFFF5F5F5);   // Readable Text

final ThemeData pillowtalkTheme = ThemeData(
  primaryColor: primaryRose,
  scaffoldBackgroundColor: backgroundMidnight,
  brightness: Brightness.dark,
  
  // Elegant Typography
  textTheme: GoogleFonts.cormorantGaramondTextTheme(
    ThemeData.dark().textTheme,
  ).apply(
    bodyColor: textSoftWhite,
    displayColor: textSoftWhite,
  ),
  
  colorScheme: const ColorScheme.dark(
    primary: primaryRose,
    secondary: secondaryGold,
    surface: backgroundMidnight,
    onSurface: textSoftWhite,
  ),
  
  appBarTheme: AppBarTheme(
    backgroundColor: backgroundMidnight,
    elevation: 0,
    titleTextStyle: GoogleFonts.cormorantGaramond(
      color: textSoftWhite,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
  
  cardTheme: CardTheme(
    color: cardDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    elevation: 4.0,
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryRose,
      foregroundColor: textSoftWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cardDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: primaryRose),
    ),
  ),
);
```

**🔄 Version Control: Complete Step 1.4**

```bash
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "feat: implement sensual theme and color palette - v0.1.3

- Created custom app theme with luxury aesthetic
- Defined primary rose and secondary gold color scheme
- Implemented dark mode with elegant typography
- Added Google Fonts integration for premium feel"

# Tag the version
git tag v0.1.4

# Push commits and tags
git push origin main
git push origin --tags
```

#### Step 1.5: Firebase Initialization & Theme Application

**Edit lib/main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const PillowtalkPagesApp());
}

class PillowtalkPagesApp extends StatelessWidget {
  const PillowtalkPagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pillowtalk Pages',
      theme: pillowtalkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

**🔄 Version Control: Complete Step 1.5 (End of Phase 1)**

```bash
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "feat: Firebase initialization and theme application - v0.2.0

- Integrated Firebase with MaterialApp.router
- Applied custom theme to main app
- Set up router configuration
- Completed Phase 1: Project Foundation"

# Tag the version (moving to Phase 2)
git tag v0.2.0

# Push commits and tags
git push origin main
git push origin --tags
```

### Phase 2: Critical Compliance & Authentication Flow

#### Step 2.1: Implement Splash Screen and Mandatory Age Gate

**Create lib/screens/splash_screen.dart**

```dart
// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Add a brief delay for splash effect
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    final bool isVerified = prefs.getBool('age_verified') ?? false;

    if (!isVerified) {
      // Show mandatory Age Gate Modal
      await _showAgeVerificationDialog();
    }

    // Check authentication state and route
    if (mounted) {
      if (FirebaseAuth.instance.currentUser != null) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  Future<void> _showAgeVerificationDialog() async {
    if (!mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardDark,
          title: const Text(
            '🔞 Mandatory Age Verification',
            style: TextStyle(
              color: primaryRose,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "This app tracks and discusses mature, adult themes, including graphic sexual content (The Spice Meter). You must be 18 years of age or older to use Pillowtalk Pages.\n\nBy continuing, you affirm that you are 18 or older.",
            style: TextStyle(color: textSoftWhite),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'I am UNDER 18',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                // Exit app immediately for underage users
                SystemNavigator.pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRose,
              ),
              child: const Text(
                'I am 18 or older',
                style: TextStyle(color: textSoftWhite),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('age_verified', true);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundMidnight,
              Color(0xFF1A0000), // Darker rose gradient
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories,
                size: 80,
                color: primaryRose,
              ),
              SizedBox(height: 24),
              Text(
                'Pillowtalk Pages',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textSoftWhite,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The Ultimate Sanctuary for Romance Readers',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryGold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryRose),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### Step 2.2: Implement Authentication Screens

**Create lib/screens/auth/login_screen.dart**

```dart
// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Login failed'),
            backgroundColor: primaryRose,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundMidnight, Color(0xFF1A0000)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.auto_stories,
                    size: 64,
                    color: primaryRose,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textSoftWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to your sanctuary',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryGold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: textSoftWhite),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: textSoftWhite),
                      prefixIcon: Icon(Icons.email, color: primaryRose),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: textSoftWhite),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: textSoftWhite),
                      prefixIcon: const Icon(Icons.lock, color: primaryRose),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: primaryRose,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(textSoftWhite),
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text(
                      'Don\'t have an account? Create one',
                      style: TextStyle(color: secondaryGold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Create lib/screens/auth/register_screen.dart**

```dart
// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the user account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update the display name
      await credential.user?.updateDisplayName(_displayNameController.text.trim());

      // Create user profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'email': _emailController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'isPro': false,
        'createdAt': FieldValue.serverTimestamp(),
        'totalBooksTracked': 0,
        'currentSpiceLevel': 0.0,
      });

      if (mounted) {
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Registration failed'),
            backgroundColor: primaryRose,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundMidnight, Color(0xFF1A0000)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.auto_stories,
                    size: 64,
                    color: primaryRose,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Join the Sanctuary',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textSoftWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your romance reader profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryGold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _displayNameController,
                    style: const TextStyle(color: textSoftWhite),
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      labelStyle: TextStyle(color: textSoftWhite),
                      prefixIcon: Icon(Icons.person, color: primaryRose),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a display name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: textSoftWhite),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: textSoftWhite),
                      prefixIcon: Icon(Icons.email, color: primaryRose),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: textSoftWhite),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: textSoftWhite),
                      prefixIcon: const Icon(Icons.lock, color: primaryRose),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: primaryRose,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: textSoftWhite),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: const TextStyle(color: textSoftWhite),
                      prefixIcon: const Icon(Icons.lock_outline, color: primaryRose),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: primaryRose,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createAccount,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(textSoftWhite),
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Already have an account? Sign in',
                      style: TextStyle(color: secondaryGold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

#### Step 2.3: Set Up Go Router Navigation

**Create lib/config/router.dart**

```dart
// lib/config/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/search/deep_trope_search_screen.dart';
import '../screens/book/book_detail_screen.dart';
import '../screens/book/add_book_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/pro/pro_club_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) {
    final User? user = FirebaseAuth.instance.currentUser;
    final bool loggedIn = user != null;
    final String location = state.uri.path;

    // Allow splash screen always
    if (location == '/splash') {
      return null;
    }

    // Redirect to login if not authenticated and not on auth pages
    if (!loggedIn && !location.startsWith('/login') && !location.startsWith('/register')) {
      return '/login';
    }

    // Redirect to home if authenticated and on auth pages
    if (loggedIn && (location.startsWith('/login') || location.startsWith('/register'))) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const DeepTropeSearchScreen(),
    ),
    GoRoute(
      path: '/book/:id',
      builder: (context, state) {
        final bookId = state.pathParameters['id']!;
        return BookDetailScreen(bookId: bookId);
      },
    ),
    GoRoute(
      path: '/add-book',
      builder: (context, state) => const AddBookScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/pro-club',
      builder: (context, state) => const ProClubScreen(),
    ),
  ],
);
```

### Phase 3: Technical MOAT & Core Feature Implementation

#### Step 3.1: Define Data Models (The Proprietary Schema)

**Create lib/models/book_model.dart**

```dart
// lib/models/book_model.dart
class RomanceBook {
  // Standard Data (From Google Books API)
  final String id;
  final String isbn;
  final String title;
  final List<String> authors;
  final String? imageUrl;
  final String? description;
  final String? publishedDate;
  final int? pageCount;

  // Proprietary MOAT Data (Aggregated from /ratings collection)
  final List<String> communityTropes;      // e.g., ['Grumpy Sunshine', 'Mutual Pining']
  final double avgSpiceOnPage;             // The Vetted Spice Meter average (0.0 - 5.0)
  final double avgEmotionalIntensity;      // The Emotional Intensity average (0.0 - 5.0)
  final List<String> topWarnings;          // Content Warnings
  final int totalUserRatings;

  const RomanceBook({
    required this.id,
    required this.isbn,
    required this.title,
    required this.authors,
    this.imageUrl,
    this.description,
    this.publishedDate,
    this.pageCount,
    this.communityTropes = const [],
    this.avgSpiceOnPage = 0.0,
    this.avgEmotionalIntensity = 0.0,
    this.topWarnings = const [],
    this.totalUserRatings = 0,
  });

  factory RomanceBook.fromJson(Map<String, dynamic> json) {
    return RomanceBook(
      id: json['id'] as String,
      isbn: json['isbn'] as String? ?? '',
      title: json['title'] as String,
      authors: List<String>.from(json['authors'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      publishedDate: json['publishedDate'] as String?,
      pageCount: json['pageCount'] as int?,
      communityTropes: List<String>.from(json['communityTropes'] ?? []),
      avgSpiceOnPage: (json['avgSpiceOnPage'] as num?)?.toDouble() ?? 0.0,
      avgEmotionalIntensity: (json['avgEmotionalIntensity'] as num?)?.toDouble() ?? 0.0,
      topWarnings: List<String>.from(json['topWarnings'] ?? []),
      totalUserRatings: json['totalUserRatings'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'authors': authors,
      'imageUrl': imageUrl,
      'description': description,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'communityTropes': communityTropes,
      'avgSpiceOnPage': avgSpiceOnPage,
      'avgEmotionalIntensity': avgEmotionalIntensity,
      'topWarnings': topWarnings,
      'totalUserRatings': totalUserRatings,
    };
  }

  RomanceBook copyWith({
    String? id,
    String? isbn,
    String? title,
    List<String>? authors,
    String? imageUrl,
    String? description,
    String? publishedDate,
    int? pageCount,
    List<String>? communityTropes,
    double? avgSpiceOnPage,
    double? avgEmotionalIntensity,
    List<String>? topWarnings,
    int? totalUserRatings,
  }) {
    return RomanceBook(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      publishedDate: publishedDate ?? this.publishedDate,
      pageCount: pageCount ?? this.pageCount,
      communityTropes: communityTropes ?? this.communityTropes,
      avgSpiceOnPage: avgSpiceOnPage ?? this.avgSpiceOnPage,
      avgEmotionalIntensity: avgEmotionalIntensity ?? this.avgEmotionalIntensity,
      topWarnings: topWarnings ?? this.topWarnings,
      totalUserRatings: totalUserRatings ?? this.totalUserRatings,
    );
  }
}
```

**Create lib/models/user_book.dart**

```dart
// lib/models/user_book.dart
enum ReadingStatus { wantToRead, reading, finished }

class UserBook {
  final String id;
  final String userId;
  final String bookId;
  final ReadingStatus status;
  final int currentPage;
  final int? totalPages;
  final DateTime dateAdded;
  final DateTime? dateStarted;
  final DateTime? dateFinished;
  final double? userSpiceRating;
  final double? userEmotionalRating;
  final List<String> userSelectedTropes;
  final List<String> userContentWarnings;
  final String? userNotes;

  const UserBook({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    this.currentPage = 0,
    this.totalPages,
    required this.dateAdded,
    this.dateStarted,
    this.dateFinished,
    this.userSpiceRating,
    this.userEmotionalRating,
    this.userSelectedTropes = const [],
    this.userContentWarnings = const [],
    this.userNotes,
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      status: ReadingStatus.values.byName(json['status'] as String),
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int?,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      dateStarted: json['dateStarted'] != null 
          ? DateTime.parse(json['dateStarted'] as String) 
          : null,
      dateFinished: json['dateFinished'] != null 
          ? DateTime.parse(json['dateFinished'] as String) 
          : null,
      userSpiceRating: (json['userSpiceRating'] as num?)?.toDouble(),
      userEmotionalRating: (json['userEmotionalRating'] as num?)?.toDouble(),
      userSelectedTropes: List<String>.from(json['userSelectedTropes'] ?? []),
      userContentWarnings: List<String>.from(json['userContentWarnings'] ?? []),
      userNotes: json['userNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookId': bookId,
      'status': status.name,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'dateAdded': dateAdded.toIso8601String(),
      'dateStarted': dateStarted?.toIso8601String(),
      'dateFinished': dateFinished?.toIso8601String(),
      'userSpiceRating': userSpiceRating,
      'userEmotionalRating': userEmotionalRating,
      'userSelectedTropes': userSelectedTropes,
      'userContentWarnings': userContentWarnings,
      'userNotes': userNotes,
    };
  }
}
```

#### Step 3.2: Google Books API Service

**Create lib/services/google_books_service.dart**

```dart
// lib/services/google_books_service.dart
import 'package:dio/dio.dart';
import '../models/book_model.dart';

class GoogleBooksService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://www.googleapis.com/books/v1',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<RomanceBook>> searchBooks(String query) async {
    try {
      final response = await _dio.get(
        '/volumes',
        queryParameters: {
          'q': query,
          'maxResults': 20,
          'printType': 'books',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        return items.map((item) => _parseBookFromGoogleBooks(item)).toList();
      } else {
        throw Exception('Failed to search books: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<RomanceBook?> getBookById(String googleBooksId) async {
    try {
      final response = await _dio.get('/volumes/$googleBooksId');

      if (response.statusCode == 200) {
        return _parseBookFromGoogleBooks(response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  RomanceBook _parseBookFromGoogleBooks(Map<String, dynamic> item) {
    final volumeInfo = item['volumeInfo'] as Map<String, dynamic>? ?? {};
    final industryIdentifiers = volumeInfo['industryIdentifiers'] as List<dynamic>? ?? [];
    
    // Extract ISBN
    String isbn = '';
    for (final identifier in industryIdentifiers) {
      if (identifier['type'] == 'ISBN_13' || identifier['type'] == 'ISBN_10') {
        isbn = identifier['identifier'] as String;
        break;
      }
    }

    // Extract image URL (prefer high resolution)
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>? ?? {};
    String? imageUrl = imageLinks['extraLarge'] as String? ??
                      imageLinks['large'] as String? ??
                      imageLinks['medium'] as String? ??
                      imageLinks['thumbnail'] as String?;
    
    // Convert HTTP to HTTPS for image URLs
    if (imageUrl != null && imageUrl.startsWith('http:')) {
      imageUrl = imageUrl.replaceFirst('http:', 'https:');
    }

    return RomanceBook(
      id: item['id'] as String,
      isbn: isbn,
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      authors: List<String>.from(volumeInfo['authors'] ?? ['Unknown Author']),
      imageUrl: imageUrl,
      description: volumeInfo['description'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      // MOAT fields are initialized as empty - will be populated from Firestore
      communityTropes: const [],
      avgSpiceOnPage: 0.0,
      avgEmotionalIntensity: 0.0,
      topWarnings: const [],
      totalUserRatings: 0,
    );
  }
}
```

#### Step 3.3: Implement Core Screens

**Create lib/screens/home/home_screen.dart**

```dart
// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeDashboard(),
    const SearchTab(),
    const LibraryTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: cardDark,
        selectedItemColor: primaryRose,
        unselectedItemColor: textSoftWhite.withOpacity(0.6),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Sanctuary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-book'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${user?.displayName ?? 'Reader'}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textSoftWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ready to dive into your next romantic adventure?',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Books Read',
                    '0', // TODO: Implement real stats
                    Icons.book,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Avg Spice Level',
                    '0.0🌶️', // TODO: Implement real stats
                    Icons.local_fire_department,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Currently Reading Section
            const Text(
              'Currently Reading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textSoftWhite,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primaryRose.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: primaryRose,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No books currently reading',
                            style: TextStyle(
                              fontSize: 16,
                              color: textSoftWhite,
                            ),
                          ),
                          Text(
                            'Add a book to get started!',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pro Club Promotion (if not Pro)
            Card(
              color: primaryRose.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: secondaryGold,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'The Connoisseur\'s Club',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: secondaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unlock unlimited book tracking and advanced trope searching',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSoftWhite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.push('/pro-club'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryGold,
                        foregroundColor: backgroundMidnight,
                      ),
                      child: const Text('Learn More'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: primaryRose,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textSoftWhite,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: secondaryGold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder tabs - implement these in separate files
class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const Center(
        child: Text('Deep Trope Search Coming Soon'),
      ),
    );
  }
}

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: const Center(
        child: Text('Your Library Coming Soon'),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Text('Profile Coming Soon'),
      ),
    );
  }
}
```

### Phase 4: Final Features & Distribution

#### Step 4.1: Placeholder Screens (To Complete Structure)

**Create remaining screen files with basic implementations:**

```dart
// lib/screens/library/library_screen.dart
import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: const Center(
        child: Text('Library implementation coming soon'),
      ),
    );
  }
}

// lib/screens/search/deep_trope_search_screen.dart
import 'package:flutter/material.dart';

class DeepTropeSearchScreen extends StatelessWidget {
  const DeepTropeSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deep Trope Search')),
      body: const Center(
        child: Text('Advanced search implementation coming soon'),
      ),
    );
  }
}

// lib/screens/book/book_detail_screen.dart
import 'package:flutter/material.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;
  
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: Center(
        child: Text('Book details for ID: $bookId'),
      ),
    );
  }
}

// lib/screens/book/add_book_screen.dart
import 'package:flutter/material.dart';

class AddBookScreen extends StatelessWidget {
  const AddBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: const Center(
        child: Text('Add book implementation coming soon'),
      ),
    );
  }
}

// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Text('Profile implementation coming soon'),
      ),
    );
  }
}

// lib/screens/pro/pro_club_screen.dart
import 'package:flutter/material.dart';

class ProClubScreen extends StatelessWidget {
  const ProClubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Connoisseur\'s Club')),
      body: const Center(
        child: Text('Pro subscription implementation coming soon'),
      ),
    );
  }
}
```

#### Step 4.2: Build and Test the App

**Command Line: Test the app**

```bash
# Run the app in debug mode
flutter run

# Run tests
flutter test

# Analyze code for issues
flutter analyze
```

#### Step 4.3: Prepare for Production

**Command Line: Build release version**

```bash
# Generate the Android App Bundle for Play Store
flutter build appbundle --release

# The output file will be at: build/app/outputs/bundle/release/app-release.aab
```

#### Step 4.4: Google Play Console Setup & Submission

**Pre-submission Checklist:**

1. **Create Privacy Policy** (Required for Play Store)
   - Host a public URL with privacy policy
   - Include Firebase data collection disclosure
   - Include Amazon Associates disclosure

2. **Google Play Console Actions:**
   - Create new app in [Play Console](https://play.google.com/console)
   - Upload the `.aab` file
   - Complete store listing with screenshots
   - Set up content rating (declare 18+ content)
   - Configure in-app products for subscriptions
   - Submit for review

**Critical Compliance for 18+ App:**

- Content Rating: Must declare sexual content
- Target Audience: 18 and over only
- App Access: Provide test credentials
- Age Gate: Implemented in splash screen

---

## 🎯 VI. Next Steps & Implementation Priority

### Immediate Implementation Order

1. **Complete Phase 1** (Project setup, Firebase, Theme, Navigation)
2. **Complete Phase 2** (Authentication, Age Gate compliance)
3. **Build and test basic app flow**
4. **Implement Phase 3** (Core features, data models)
5. **Add Pro features and monetization**
6. **Final testing and Play Store submission**

### Key Success Metrics

- **Week 1:** Basic app with authentication working
- **Week 2:** Core tracking features implemented
- **Week 3:** MOAT features (Spice Meter, Trope Engine) functional
- **Week 4:** Play Store submission ready

This roadmap provides everything needed to build Pillowtalk Pages from conception to Play Store distribution, with all legal compliance, technical implementation details, and strategic positioning included.

---

## 📝 Complete Git Version Control Workflow

### After Each Major Step

Execute these commands after completing each step (1.1, 1.2, etc.):

```bash
# Stage all changes
git add .

# Commit with descriptive message following conventional commits
git commit -m "feat: [step description] - v[version]

- [bullet point of what was accomplished]
- [another major change]
- [any important notes]"

# Tag the version
git tag v[version]

# Push commits and tags
git push origin main
git push origin --tags
```

### Detailed Version History Plan

| Step | Version | Commit Message | Key Changes |
|------|---------|----------------|-------------|
| **1.1** | v0.1.0 | `feat: project setup and dependencies` | Flutter project, pubspec.yaml |
| **1.2** | v0.1.1 | `feat: Firebase project setup and configuration` | Firebase console, FlutterFire CLI |
| **1.3** | v0.1.2 | `feat: Firestore security rules for MOAT protection` | Security rules implementation |
| **1.4** | v0.1.3 | `feat: implement sensual theme and color palette` | Custom theme, color scheme |
| **1.5** | v0.2.0 | `feat: Firebase initialization and theme application` | main.dart, router setup |
| **2.1** | v0.2.1 | `feat: splash screen and mandatory age gate` | Age verification compliance |
| **2.2** | v0.2.2 | `feat: authentication screens implementation` | Login/register UI |
| **2.3** | v0.2.3 | `feat: navigation setup with go_router` | Route configuration |
| **3.1** | v0.3.0 | `feat: data models for MOAT implementation` | Book and user models |
| **3.2** | v0.3.1 | `feat: Google Books API service integration` | API service layer |
| **3.3** | v0.3.2 | `feat: core screens and home dashboard` | Main UI screens |
| **4.1** | v0.4.0 | `feat: placeholder screens for full structure` | Complete app structure |
| **4.2** | v0.4.1 | `feat: build and testing setup` | Debug/test configuration |
| **4.3** | v0.4.2 | `feat: production build preparation` | Release build setup |
| **4.4** | v1.0.0 | `feat: Play Store submission ready` | Production release |

### Branch Strategy (Optional)

For a solo project, you can work directly on `main`, but for larger features consider:

```bash
# Create feature branch
git checkout -b feature/spice-meter-modal

# Work on feature, commit regularly
git add .
git commit -m "feat: implement spice meter UI components"

# Merge back to main when complete
git checkout main
git merge feature/spice-meter-modal
git tag v0.3.3
git push origin main --tags
```

### Release Preparation Checklist

Before tagging v1.0.0 (Play Store submission):

```bash
# Final code review
flutter analyze

# Run all tests
flutter test

# Build release version
flutter build appbundle --release

# Final commit
git add .
git commit -m "chore: prepare for v1.0.0 release

- Final code cleanup and analysis
- Generated production App Bundle
- Ready for Play Store submission"

# Create release tag
git tag v1.0.0

# Push everything
git push origin main
git push origin --tags
```

This version control strategy ensures complete traceability of your development progress and provides clear rollback points if needed during development.
