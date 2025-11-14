# CI/CD Workflows

## Build Multi-Platform Workflow

Automatically builds the MeshCore SAR app for Android, iOS, macOS, and Windows.

### Triggers

- **Push to main/develop**: Builds with version `1.0.0+1` (from pubspec.yaml)
- **Pull requests to main**: Test builds only
- **Version tags** (e.g., `v1.2.3`): Release builds with versioned artifacts
- **Manual**: Via GitHub Actions UI

### Creating a Release

1. **Ensure your local version is 1.0.0**:
   ```bash
   # pubspec.yaml should show:
   version: 1.0.0+1
   ```

2. **Commit all changes**:
   ```bash
   git add .
   git commit -m "Prepare for release"
   git push origin main
   ```

3. **Create and push a version tag**:
   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```

4. **GitHub Actions will**:
   - Temporarily patch version to `1.2.3+<timestamp>` in builds only
   - Build Android APK & App Bundle
   - Build iOS app (unsigned - configure secrets for signed IPA)
   - Build macOS DMG
   - Build Windows executable (ZIP)
   - Create a draft GitHub release with all artifacts

5. **Publish the release**:
   - Go to GitHub Releases
   - Edit the draft release
   - Add release notes
   - Publish

### Build Artifacts

| Platform | Artifact | Location |
|----------|----------|----------|
| Android APK | `app-release.apk` | `artifacts/android-apk/` |
| Android Bundle | `app-release.aab` | `artifacts/android-appbundle/` |
| macOS | `MeshCore-SAR.dmg` | `artifacts/macos-dmg/` |
| iOS | `Runner.app` | `artifacts/ios-build/` (unsigned) |
| Windows | `MeshCore-SAR-Windows.zip` | `artifacts/windows-executable/` |

### iOS Code Signing (Optional)

To build signed IPA files, add these repository secrets:

1. **IOS_P12_BASE64**: Base64-encoded .p12 certificate
   ```bash
   base64 -i Certificate.p12 | pbcopy
   ```

2. **IOS_P12_PASSWORD**: Password for the .p12 certificate

3. **IOS_PROVISION_PROFILE_BASE64**: Base64-encoded provisioning profile
   ```bash
   base64 -i Profile.mobileprovision | pbcopy
   ```

Then uncomment the signing steps in the workflow.

### Version Numbering

- **Local**: Always keep `pubspec.yaml` at `version: 1.0.0+1`
- **CI builds**: Uses `1.0.0+1` for regular commits
- **Release builds**: Uses `<tag>+<timestamp>` (e.g., `1.2.3+1729512345`)
- **No commits**: Version changes are temporary and never committed back

### Troubleshooting

**Build fails on macOS DMG creation**:
- The workflow tries `create-dmg` first, then falls back to `hdiutil`
- Check if app icon path exists at `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png`

**Windows build fails**:
- Ensure Windows desktop is properly configured in project
- Run locally: `flutter config --enable-windows-desktop && flutter build windows`

**iOS build fails**:
- Check CocoaPods version and dependencies
- Review code signing configuration (currently set to `--no-codesign`)

**Android build fails**:
- Verify Java 17 is compatible with your Gradle version
- Check `android/build.gradle` for minimum SDK requirements
