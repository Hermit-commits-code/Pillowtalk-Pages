# GitHub Pages Legal Documents URLs

**Repository**: https://github.com/Hermit-commits-code/Pillowtalk-Pages  
**GitHub Pages Base**: https://hermit-commits-code.github.io/Pillowtalk-Pages/

---

## Legal Documents URLs

Once GitHub Pages is enabled on your repository's main branch (Settings → Pages), these documents will be publicly accessible:

### Privacy Policy
```
https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/PRIVACY_POLICY.md
```

### Terms of Service
```
https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/TERMS_OF_SERVICE.md
```

### Release Notes
```
https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/RELEASE_NOTES_v0.4.1.md
```

### Documentation Index
```
https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/README.md
```

### Changelog
```
https://hermit-commits-code.github.io/Pillowtalk-Pages/CHANGELOG.md
```

---

## How to Enable GitHub Pages

1. Go to your repository: https://github.com/Hermit-commits-code/Pillowtalk-Pages
2. Click **Settings** (top right)
3. Go to **Pages** (left sidebar)
4. Under "Source", select:
   - Branch: **main**
   - Folder: **/ (root)**
5. Click **Save**
6. GitHub will provide your Pages URL

**Note**: GitHub Pages is now enabled on the main branch and automatically serves files from the root directory, including all files in the `docs/` folder.

---

## Integrating URLs into the App

### In `profile_screen.dart`

Update the "Legal" section to link to these GitHub Pages URLs:

```dart
// Example implementation:
InkWell(
  onTap: () async {
    final url = Uri.parse(
      'https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/PRIVACY_POLICY.md'
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
  child: const Text('Privacy Policy'),
),
InkWell(
  onTap: () async {
    final url = Uri.parse(
      'https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/TERMS_OF_SERVICE.md'
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
  child: const Text('Terms of Service'),
),
```

**Note**: You'll need to import `url_launcher`:
```dart
import 'package:url_launcher/url_launcher.dart';
```

---

## Testing the URLs

Before deploying to Play Store, test that the URLs work:

1. Build and run the app in debug mode
2. Navigate to Profile Screen → Settings/Legal
3. Tap each link
4. Verify the document opens in browser

---

## Play Store Listing Information

For your Play Store app listing, add these URLs:

| Field | Value |
|-------|-------|
| **Privacy Policy URL** | https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/PRIVACY_POLICY.md |
| **Terms of Service URL** | https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/TERMS_OF_SERVICE.md |
| **Contact Email** | support@spicyreads.app |

These are required by Google Play Store for app listings.

---

## File Structure on GitHub Pages

Your files will be accessible at these paths:

```
Repository Root
├── docs/
│   ├── PRIVACY_POLICY.md            → /docs/PRIVACY_POLICY.md
│   ├── TERMS_OF_SERVICE.md          → /docs/TERMS_OF_SERVICE.md
│   ├── RELEASE_NOTES_v0.4.1.md      → /docs/RELEASE_NOTES_v0.4.1.md
│   ├── README.md                    → /docs/README.md
│   ├── v0.4.0_completion_status.md  → /docs/v0.4.0_completion_status.md
│   └── ... (other docs)
├── CHANGELOG.md                      → /CHANGELOG.md
└── ... (other files)
```

**Base URL**: `https://hermit-commits-code.github.io/Pillowtalk-Pages/`

---

## FAQ

### Q: How long does GitHub Pages take to deploy?
**A**: Usually 1-2 minutes after you enable it or push changes.

### Q: Can I use custom domain instead?
**A**: Yes! You can use a custom domain by updating Settings → Pages → Custom domain. But GitHub's default domain works fine.

### Q: What if the URL doesn't work?
**A**: 
1. Check that GitHub Pages is enabled in Settings → Pages
2. Verify the file exists in the docs/ folder on main branch
3. Wait 2-3 minutes for GitHub Pages to rebuild
4. Check your internet connection

### Q: Can I make the documents private?
**A**: No, GitHub Pages documents are public. This is required for Play Store compliance anyway.

### Q: What if I need to update the legal documents?
**A**: 
1. Edit the markdown file in `docs/` folder
2. Commit and push to main branch
3. GitHub Pages will update within 1-2 minutes
4. URLs remain the same (always point to latest version)

---

## Security Considerations

- ✅ URLs use HTTPS (secure)
- ✅ Documents are read-only (no edit from app)
- ✅ GitHub enforces HTTPS
- ✅ Documents are versioned (tracked in git history)
- ✅ Changes are auditable (commit history)

---

## Next Steps

1. **Verify GitHub Pages is enabled**
   - Go to Settings → Pages
   - Check "Source" is set to main branch

2. **Test the URLs**
   - Open each URL in browser
   - Verify content displays correctly

3. **Update Profile Screen**
   - Add url_launcher import (if not already present)
   - Link to the GitHub Pages URLs
   - Test in app

4. **Submit to Play Store**
   - Build AAB: `flutter build appbundle --release`
   - Upload to Google Play Console
   - Add URL launcher URLs to app store listing
   - Submit for review

---

**GitHub Pages is the recommended hosting solution because it's:**
- Free and always available
- Automatically versioned with your code
- Secure (HTTPS by default)
- Auditable (commit history)
- Play Store compliant

---

*Last updated: November 3, 2025*
