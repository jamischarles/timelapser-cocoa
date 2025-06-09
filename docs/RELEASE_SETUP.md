# 🚀 Release Pipeline Setup Guide

This guide explains how to set up automated macOS app releases with GitHub Actions, including code signing, notarization, and DMG creation.

## 📋 Overview

We provide 3 release pipeline options:

1. **Simple Release** (`.github/workflows/release.yml`) - Basic DMG creation without signing
2. **Professional Release** (`.github/workflows/release-signed.yml`) - Code signing and notarization  
3. **Advanced Release** (`.github/workflows/release-advanced.yml`) - Universal binaries with caching

## 🎯 Quick Start (Option 1: Simple Release)

For immediate use without code signing:

1. The simple release pipeline is ready to use immediately
2. Triggers automatically when you create a GitHub release
3. Creates a DMG file and attaches it to the release
4. No Apple Developer account required

**Usage:**
1. Create a new release on GitHub with a tag (e.g., `v1.0.0`)
2. The workflow will automatically build and create a DMG
3. The DMG will be attached to the release

## 🔐 Professional Setup (Options 2 & 3: Code Signing & Notarization)

For professional distribution, you'll need code signing and notarization.

### Prerequisites

1. **Apple Developer Account** ($99/year)
2. **Developer ID Application Certificate**
3. **App-Specific Password**
4. **Team ID**

### Step 1: Apple Developer Setup

#### A. Get Developer ID Application Certificate

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Certificates** → **+** button
4. Select **Developer ID Application** (for distribution outside App Store)
5. Follow the instructions to create and download the certificate

#### B. Export Certificate

1. Open **Keychain Access** on your Mac
2. Find your "Developer ID Application" certificate
3. Right-click → **Export**
4. Save as `.p12` file with a password
5. Convert to Base64: `base64 -i certificate.p12 | pbcopy`

#### C. Create App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in → **App-Specific Passwords**
3. Generate new password
4. Save it securely

#### D. Find Your Team ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Look for **Team ID** in the top-right corner (e.g., `AB1234CD56`)

### Step 2: GitHub Secrets Configuration

Go to your repository → **Settings** → **Secrets and variables** → **Actions**

Add these repository secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `BUILD_CERTIFICATE_BASE64` | Base64 encoded .p12 certificate | `MIIKaAIBAzCC...` |
| `P12_PASSWORD` | Password for the .p12 file | `your-certificate-password` |
| `KEYCHAIN_PASSWORD` | Random password for temporary keychain | `temp-keychain-123` |
| `CODESIGN_IDENTITY` | Certificate identity name | `Developer ID Application: Your Name (AB1234CD56)` |
| `APPLE_ID` | Your Apple ID email | `your-email@icloud.com` |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password | `abcd-efgh-ijkl-mnop` |
| `APPLE_TEAM_ID` | Your team ID | `AB1234CD56` |

### Step 3: Find Your Certificate Identity

Run this command on your Mac to find the exact identity string:

```bash
security find-identity -v -p codesigning
```

Copy the full string like: `Developer ID Application: John Doe (AB1234CD56)`

## ⚙️ Workflow Configuration

### Customize App Settings

Edit the environment variables in your chosen workflow file:

```yaml
env:
  APP_NAME: "YourAppName"           # Change this to your app name
  BUNDLE_ID: "com.yourcompany.app"  # Change this to your bundle identifier
```

### Trigger Options

Each workflow supports two triggers:

1. **Automatic**: When you publish a GitHub release
2. **Manual**: Via workflow dispatch (Actions tab → "Run workflow")

## 🏗️ Build Process

### Option 1: Simple Release
- Builds with `swift build -c release`
- Creates basic .app bundle
- Generates DMG with `create-dmg`
- No signing or notarization

### Option 2: Professional Release  
- Builds with Swift Package Manager
- Code signs the .app bundle
- Creates DMG with professional layout
- Code signs the DMG
- Submits for notarization
- Staples notarization ticket

### Option 3: Advanced Release
- Builds universal binary (Intel + Apple Silicon)
- Uses caching for faster builds
- Professional DMG creation
- Complete signing and notarization
- Detailed release notes generation

## 📦 DMG Customization

You can customize the DMG appearance by modifying the `create-dmg` parameters:

```bash
create-dmg \
  --volname "Your App Installer" \
  --volicon "path/to/volume-icon.icns" \
  --background "path/to/background.png" \
  --window-pos 200 120 \
  --window-size 600 300 \
  --icon-size 100 \
  --icon "YourApp.app" 175 120 \
  --app-drop-link 425 120 \
  "YourApp.dmg" \
  "YourApp.app"
```

## 🚀 Creating a Release

### Method 1: GitHub UI
1. Go to your repository on GitHub
2. Click **Releases** → **Create a new release**
3. Choose or create a tag (e.g., `v1.0.0`)
4. Add release title and description
5. Click **Publish release**

### Method 2: Command Line
```bash
# Create and push a tag
git tag v1.0.0
git push origin v1.0.0

# Create release via GitHub CLI
gh release create v1.0.0 --title "Version 1.0.0" --notes "Release notes here"
```

### Method 3: Manual Trigger
1. Go to **Actions** tab
2. Select your workflow
3. Click **Run workflow**
4. Enter the tag/version
5. Click **Run workflow**

## 🔍 Troubleshooting

### Common Issues

1. **"No signing identity found"**
   - Check `CODESIGN_IDENTITY` secret matches exactly
   - Verify certificate is properly imported

2. **"Notarization failed"**
   - Verify all Apple secrets are correct
   - Check Team ID matches your certificate
   - Ensure app-specific password is valid

3. **"DMG creation failed"**
   - Check app icon path exists
   - Verify .app bundle structure is correct

### Debug Steps

1. **Enable debug logging**: Re-run workflow with debug logging enabled
2. **Check certificate**: Use workflow dispatch to test signing separately
3. **Verify secrets**: Double-check all secret values in repository settings

### Manual Verification

Test your setup locally:

```bash
# Test code signing
codesign --verify --verbose YourApp.app

# Test notarization  
xcrun notarytool submit YourApp.dmg --apple-id your@email.com --password xxxx --team-id XXXXX --wait

# Test DMG
open YourApp.dmg
```

## 📈 Performance Optimization

The advanced workflow includes several optimizations:

1. **Caching**: Swift build artifacts cached with zstd compression
2. **Universal binaries**: Single DMG works on Intel and Apple Silicon
3. **Parallel processing**: Multiple steps run concurrently where possible
4. **Smart caching**: Only rebuilds when Package.swift/Package.resolved changes

Typical build times:
- **First build**: 8-12 minutes
- **Cached build**: 3-5 minutes
- **Universal binary**: +2-3 minutes vs single architecture

## 🛡️ Security Best Practices

1. **Secrets Management**:
   - Never commit certificates or passwords to repository
   - Use repository secrets, not organization secrets for certificates
   - Regularly rotate app-specific passwords

2. **Certificate Security**:
   - Keep .p12 files secure and encrypted
   - Use strong passwords for certificate export
   - Consider using separate certificates for different apps

3. **Workflow Security**:
   - Limit workflow permissions to minimum required
   - Use specific action versions, not `@main`
   - Review third-party actions before use

## 📚 Additional Resources

- [Apple Code Signing Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [create-dmg Tool](https://github.com/create-dmg/create-dmg)
- [Swift Package Manager](https://swift.org/package-manager/)

## 🤝 Support

If you encounter issues:

1. Check the workflow logs in the Actions tab
2. Verify all secrets are properly set
3. Test the signing process locally first
4. Review Apple's notarization status page for service issues

---

**Need help?** Open an issue in this repository with:
- Workflow logs (remove sensitive information)
- Steps you've tried
- Expected vs actual behavior 