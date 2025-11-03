# GitHub Pages Setup - Fix 404 Errors

**Problem**: Documents are returning 404 errors when accessed via GitHub Pages  
**Solution**: Enable GitHub Pages properly with correct configuration

---

## Step 1: Push Your Changes

First, commit and push the latest changes to your main branch:

```bash
cd /home/hermit/Desktop/pillowtalk_pages
git add .
git commit -m "Add legal documents, release notes, and navigation bar"
git push origin main
```

---

## Step 2: Enable GitHub Pages in Repository Settings

1. Go to: **https://github.com/Hermit-commits-code/Pillowtalk-Pages**

2. Click **Settings** (top right of repo)

3. In left sidebar, click **Pages** (under "Code and automation")

4. Under **Build and deployment**:
   - **Source**: Select **Deploy from a branch**
   - **Branch**: Select **main**
   - **Folder**: Select **/ (root)**

5. Click **Save**

6. Wait 1-2 minutes for GitHub to build your site

---

## Step 3: Verify Pages is Active

After enabling:

1. Go back to the repo
2. Look for a message: "Your site is published at: `https://hermit-commits-code.github.io/Pillowtalk-Pages/`"
3. Wait a few minutes (sometimes takes up to 5 minutes initially)

---

## Step 4: Test the URLs

Once enabled, test these URLs (should NOT get 404):

### Privacy Policy
```
https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/PRIVACY_POLICY.md
```

### Terms of Service
```
https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/TERMS_OF_SERVICE.md
```

### Changelog
```
https://hermit-commits-code.github.io/Pillowtalk-Pages/CHANGELOG.md
```

### Release Notes
```
https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/RELEASE_NOTES_v0.4.1.md
```

---

## Step 5: Update App Links

Now update the Profile Screen to use the GitHub Pages URLs. Edit `lib/screens/profile/profile_screen.dart`:

```dart
// Add these URL launcher functions in the ProfileScreen
Future<void> _launchPrivacyPolicy() async {
  final url = Uri.parse(
    'https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/PRIVACY_POLICY.md',
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

Future<void> _launchTermsOfService() async {
  final url = Uri.parse(
    'https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/TERMS_OF_SERVICE.md',
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
```

Then in the UI, add buttons:

```dart
ListTile(
  title: const Text('Privacy Policy'),
  onTap: _launchPrivacyPolicy,
  trailing: const Icon(Icons.open_in_new),
),
ListTile(
  title: const Text('Terms of Service'),
  onTap: _launchTermsOfService,
  trailing: const Icon(Icons.open_in_new),
),
```

---

## Troubleshooting GitHub Pages 404s

### If you still get 404 errors:

1. **Check file exists**: Verify file is in the repo
   ```bash
   ls -la docs/PRIVACY_POLICY.md
   # Should show the file
   ```

2. **Wait longer**: GitHub Pages can take 2-5 minutes initially
   - Try again after 5 minutes

3. **Check Settings**: Verify Pages is enabled
   - Go to Settings → Pages
   - Make sure it shows "Your site is live at..."

4. **Clear cache**: Browser might have cached the 404
   - Open link in private/incognito window
   - Or press Ctrl+Shift+Delete to clear cache

5. **Check branch**: Confirm main branch is selected in Pages settings

6. **Commit the _config.yml**: I've added a Jekyll config file
   ```bash
   git add _config.yml
   git commit -m "Add Jekyll config for GitHub Pages"
   git push origin main
   ```

---

## Understanding GitHub Pages URLs

When you enable GitHub Pages:

| File Location | Accessible At |
|---------------|----------------|
| `docs/PRIVACY_POLICY.md` | `/docs/PRIVACY_POLICY.md` (relative) |
| `CHANGELOG.md` | `/CHANGELOG.md` (relative) |
| `README.md` | `/README.md` (relative) |

**Full URL Format**: `https://hermit-commits-code.github.io/Pillowtalk-Pages/[relative-path]`

---

## Common Issues & Solutions

### Issue: "This site can't be reached"
**Solution**: GitHub Pages might not be fully deployed yet. Wait 5 minutes and try again.

### Issue: File shows "404 Not Found" page
**Solution**: 
1. Verify the file exists in your repo on main branch
2. Check the exact file path matches
3. Make sure the file was committed and pushed

### Issue: Page shows raw markdown instead of rendering
**Solution**: This is expected for GitHub Pages showing markdown. The markdown will render in most browsers. If you need HTML rendering, you can add a `.nojekyll` file to disable Jekyll processing, or use a custom domain.

### Issue: Images/CSS not loading
**Solution**: Use relative URLs starting with `/Pillowtalk-Pages/` in your docs:
```markdown
![alt](/Pillowtalk-Pages/images/example.png)
```

---

## Once GitHub Pages is Working

Your URLs will be:

```
Privacy Policy:
https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/PRIVACY_POLICY.md

Terms of Service:
https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/TERMS_OF_SERVICE.md

Release Notes:
https://hermit-commits-code.github.io/Pillowtalk-Pages/docs/RELEASE_NOTES_v0.4.1.md

Changelog:
https://hermit-commits-code.github.io/Pillowtalk-Pages/CHANGELOG.md
```

Use these in your app's Profile Screen to link to the legal documents!

---

## Next Steps

1. ✅ Commit and push all changes
2. ✅ Enable GitHub Pages in repository settings
3. ✅ Wait 2-5 minutes for deployment
4. ✅ Test the URLs work
5. ✅ Update app links in Profile Screen
6. ✅ Test app links work in debug build
7. ✅ Build AAB and submit to Play Store

---

*GitHub Pages Setup Guide - November 3, 2025*
