# Fastlane TestFlight Setup for CI/CD

This document describes how to configure Fastlane for automatic iOS beta deployments to TestFlight from GitHub Actions.

## Overview

The CI/CD pipeline automatically builds and uploads iOS beta builds to TestFlight for every push to `main`, `develop`, or release tags. This provides:

- **Automatic TestFlight distribution** for beta testers
- **Version management** with build number increments
- **Code signing** handled automatically in CI
- **Release notes** from git commits

## Prerequisites

Before setting up the CI/CD pipeline, ensure you have:

1. **Apple Developer Account** with:
   - Paid Apple Developer Program membership ($99/year)
   - App registered in App Store Connect
   - TestFlight enabled for your app

2. **App Store Connect Access**:
   - Admin or App Manager role
   - App-specific password generated

3. **Code Signing Certificates**:
   - Distribution certificate (`.p12` file)
   - Ad Hoc or App Store provisioning profile

## Required GitHub Secrets

Configure these secrets in your GitHub repository settings (`Settings` → `Secrets and variables` → `Actions`):

### Certificate & Provisioning

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `IOS_P12_BASE64` | Base64-encoded distribution certificate | See [Exporting Certificate](#exporting-certificate) |
| `IOS_P12_PASSWORD` | Password for the .p12 certificate | Password you set when exporting |
| `IOS_PROVISION_PROFILE_BASE64` | Base64-encoded provisioning profile | See [Exporting Provisioning Profile](#exporting-provisioning-profile) |

### Apple Account Authentication

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `FASTLANE_USER` | Apple ID email address | Your Apple Developer account email (e.g., `hey@dz0ny.dev`) |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | App-specific password | See [Generating App-Specific Password](#generating-app-specific-password) |
| `FASTLANE_SESSION` | *(Optional)* Fastlane session for 2FA | See [Handling 2FA](#handling-2fa-optional) |

## Step-by-Step Setup

### 1. Exporting Certificate

#### Export Distribution Certificate from Keychain

1. Open **Keychain Access** on macOS
2. Select **login** keychain in the left sidebar
3. Select **Certificates** category
4. Find your **Apple Distribution** certificate
   - Look for "Apple Distribution: Your Name (Team ID)"
   - Ensure it has a valid private key (arrow to expand)
5. **Right-click** → **Export "Apple Distribution: ..."**
6. Save as: `distribution.p12`
7. **Set a strong password** (you'll need this for `IOS_P12_PASSWORD`)
8. Click **Save**

#### Convert to Base64

```bash
# Encode the .p12 file to base64
base64 -i distribution.p12 | pbcopy
```

The base64 string is now in your clipboard. Add it as `IOS_P12_BASE64` secret.

**Security Note**: Delete `distribution.p12` after encoding!

### 2. Exporting Provisioning Profile

#### Download from Apple Developer Portal

1. Log in to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Profiles** in the left sidebar
4. Find your **App Store** or **Ad Hoc** provisioning profile
   - Must match your app's bundle identifier: `com.meshcore.sar.meshcoreSarApp`
5. Click the profile → **Download**
6. Save as: `profile.mobileprovision`

#### Convert to Base64

```bash
# Encode the provisioning profile to base64
base64 -i profile.mobileprovision | pbcopy
```

The base64 string is now in your clipboard. Add it as `IOS_PROVISION_PROFILE_BASE64` secret.

**Security Note**: Delete `profile.mobileprovision` after encoding!

### 3. Generating App-Specific Password

App-specific passwords are required for App Store Connect API access when 2FA is enabled.

1. Log in to [Apple ID Account](https://appleid.apple.com/)
2. Navigate to **Sign-In and Security** → **App-Specific Passwords**
3. Click **Generate an app-specific password**
4. Enter a label: `GitHub Actions Fastlane`
5. Click **Create**
6. **Copy the generated password** (format: `xxxx-xxxx-xxxx-xxxx`)
   - This will only be shown once!
7. Add it as `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` secret

### 4. Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each of the following:

   **IOS_P12_BASE64**:
   ```
   Paste the base64-encoded certificate from step 1
   ```

   **IOS_P12_PASSWORD**:
   ```
   The password you set when exporting the .p12 certificate
   ```

   **IOS_PROVISION_PROFILE_BASE64**:
   ```
   Paste the base64-encoded provisioning profile from step 2
   ```

   **FASTLANE_USER**:
   ```
   hey@dz0ny.dev
   ```

   **FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD**:
   ```
   xxxx-xxxx-xxxx-xxxx
   ```

### 5. Handling 2FA (Optional)

If your Apple account has two-factor authentication enabled, Fastlane may require a session token for long-running CI jobs.

#### Generate Fastlane Session

On your local machine:

```bash
# Install Fastlane if not already installed
gem install fastlane

# Generate session token
fastlane spaceauth -u hey@dz0ny.dev
```

You'll be prompted for:
1. Apple ID password
2. 2FA code (sent to your device)

Fastlane will output a session cookie. Copy the entire cookie string and add it as `FASTLANE_SESSION` secret.

**Note**: Session tokens expire after ~30 days. You'll need to regenerate periodically.

**Alternative**: If you don't set `FASTLANE_SESSION`, Fastlane will use the app-specific password, which works for most cases.

## Workflow Configuration

The workflow is already configured in `.github/workflows/build-multiplatform.yml`:

- **Triggers**: Pushes to `main`, `develop`, or version tags (`v*`)
- **Runs on**: macOS runner (required for iOS builds)
- **Fastlane Lane**: `beta` (builds IPA and uploads to TestFlight)

### What the Workflow Does

1. **Checks out code** and downloads versioned `pubspec.yaml` (for tags)
2. **Sets up Flutter** and installs dependencies
3. **Generates localizations** (`flutter gen-l10n`)
4. **Installs CocoaPods** dependencies
5. **Sets up Ruby** and installs Fastlane
6. **Imports code signing certificate** into temporary keychain
7. **Imports provisioning profile**
8. **Runs Fastlane beta lane**:
   - Increments build number
   - Builds signed IPA
   - Uploads to TestFlight
9. **Cleans up keychain** (security)
10. **Uploads logs** if build fails (for debugging)

## Fastlane Configuration

The Fastlane configuration is in `ios/fastlane/`:

### Fastfile

```ruby
platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    increment_build_number(xcodeproj: "Runner.xcodeproj")
    build_app(workspace: "Runner.xcworkspace", scheme: "Runner")
    upload_to_testflight
  end
end
```

### Appfile

Contains your app configuration:
- Bundle identifier: `com.meshcore.sar.meshcoreSarApp`
- Apple ID: `hey@dz0ny.dev`
- Team IDs for App Store Connect and Developer Portal

## Testing the Setup

1. **Push a commit** to `main` or `develop` branch:
   ```bash
   git checkout main
   git commit --allow-empty -m "Test TestFlight deployment"
   git push origin main
   ```

2. **Monitor the workflow**:
   - Go to **Actions** tab in GitHub
   - Click on the running workflow
   - Watch the **Deploy iOS Beta to TestFlight** job

3. **Check TestFlight**:
   - Log in to [App Store Connect](https://appstoreconnect.apple.com/)
   - Navigate to **My Apps** → **MeshCore SAR** → **TestFlight**
   - You should see a new build processing (takes 5-15 minutes)

4. **Verify build**:
   - Once processing completes, the build is available for testing
   - Add internal testers in TestFlight
   - Testers will receive notification to download via TestFlight app

## Troubleshooting

### "Invalid certificate" error

**Cause**: Certificate doesn't match the provisioning profile or is expired.

**Solutions**:
- Verify certificate is **Distribution** type (not Development)
- Check certificate expiration date in Keychain Access
- Ensure provisioning profile includes the certificate
- Re-export and re-encode both certificate and profile

### "Invalid provisioning profile" error

**Cause**: Provisioning profile doesn't match app bundle ID or is expired.

**Solutions**:
- Verify bundle ID: `com.meshcore.sar.meshcoreSarApp`
- Check profile type: App Store or Ad Hoc (not Development)
- Regenerate profile in Apple Developer Portal
- Ensure profile includes all required devices (for Ad Hoc)

### "Authentication failed" error

**Cause**: Apple ID credentials are incorrect or expired.

**Solutions**:
- Verify `FASTLANE_USER` matches your Apple ID email
- Regenerate `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`
- If using 2FA, regenerate `FASTLANE_SESSION` token
- Check Apple Developer account is active (membership paid)

### "Build number conflict" error

**Cause**: Build number already exists in TestFlight.

**Solutions**:
- Fastlane auto-increments build number, but may fail if out of sync
- Manually increment version in `pubspec.yaml`
- Or modify Fastfile to use timestamp-based build numbers:
  ```ruby
  increment_build_number(
    build_number: Time.now.to_i.to_s,
    xcodeproj: "Runner.xcodeproj"
  )
  ```

### "Session expired" error

**Cause**: `FASTLANE_SESSION` token expired (lasts ~30 days).

**Solutions**:
- Regenerate session token: `fastlane spaceauth -u hey@dz0ny.dev`
- Update `FASTLANE_SESSION` secret in GitHub
- Or remove the secret and rely on app-specific password only

### Workflow doesn't run

**Cause**: Conditional check failed (wrong branch or secrets missing).

**Solutions**:
- Verify you pushed to `main` or `develop` branch
- Check all required secrets are configured in GitHub
- Review workflow logs for conditional evaluation

## Advanced Configuration

### Custom Release Notes

Add release notes from git commits:

Edit `ios/fastlane/Fastfile`:

```ruby
lane :beta do
  increment_build_number(xcodeproj: "Runner.xcodeproj")
  build_app(workspace: "Runner.xcworkspace", scheme: "Runner")

  # Generate changelog from git
  changelog = changelog_from_git_commits(
    pretty: "- %s",
    merge_commit_filtering: "exclude_merges"
  )

  upload_to_testflight(
    changelog: changelog,
    skip_waiting_for_build_processing: true
  )
end
```

### Selective TestFlight Groups

Upload to specific tester groups:

```ruby
upload_to_testflight(
  groups: ["Internal Testers", "Beta Team"],
  distribute_external: false,
  skip_waiting_for_build_processing: true
)
```

### Automatic Screenshot Upload

Generate and upload screenshots for App Store:

```ruby
lane :screenshots do
  snapshot
end

lane :beta do
  increment_build_number(xcodeproj: "Runner.xcodeproj")
  build_app(workspace: "Runner.xcworkspace", scheme: "Runner")
  upload_to_testflight
  upload_to_app_store(
    screenshots_path: "./fastlane/screenshots",
    skip_binary_upload: true,
    skip_metadata: true
  )
end
```

## Security Best Practices

1. **Never commit secrets** to your repository
2. **Rotate certificates** before expiration (annually)
3. **Regenerate app-specific passwords** periodically
4. **Use temporary keychains** in CI (already implemented)
5. **Delete certificates** after encoding to base64
6. **Limit GitHub Actions secrets** to repository scope
7. **Review workflow logs** for sensitive data leaks
8. **Enable branch protection** for `main` and `develop`

## Cost Considerations

### Apple Developer Program

- **$99/year** for individual account
- **$299/year** for enterprise account
- Required for TestFlight distribution

### GitHub Actions

- **Free tier**: 2,000 minutes/month for private repos
- **macOS runners**: 10x multiplier (1 min = 10 mins)
- **Typical iOS build**: ~15-20 minutes (~150-200 minutes counted)
- **Monthly estimate**: ~10 builds = ~2,000 minutes (free tier limit)

**Tip**: Use caching and selective triggers to minimize build minutes.

## Additional Resources

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Fastlane TestFlight Guide](https://docs.fastlane.tools/actions/upload_to_testflight/)
- [Apple Developer Portal](https://developer.apple.com/account)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [GitHub Actions for iOS](https://docs.github.com/en/actions/deployment/deploying-xcode-applications)
- [Fastlane Best Practices](https://docs.fastlane.tools/best-practices/)

## Support

For issues with:
- **Fastlane**: Check [Fastlane Docs](https://docs.fastlane.tools/) or [GitHub Issues](https://github.com/fastlane/fastlane/issues)
- **GitHub Actions**: Check [workflow logs](https://github.com/meshcore-dev/meshcore_sar_app/actions)
- **Code signing**: Check [Apple's Code Signing Guide](https://developer.apple.com/support/code-signing/)
- **TestFlight**: Check [App Store Connect Help](https://developer.apple.com/support/app-store-connect/)
