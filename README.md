# MeshCore SAR App

A Flutter-based Search and Rescue (SAR) application that communicates with MeshCore mesh network devices via Bluetooth Low Energy (BLE).

## Features

- **Real-time Messaging**: Receive and display messages from MeshCore mesh network
- **Contact Management**: Track team members, repeaters, and communication channels
- **SAR Markers**: Special location markers for found persons, fires, and staging areas
- **Interactive Map**: View team locations and SAR markers on an interactive map with multiple layer options:
  - OpenStreetMap (default)
  - OpenTopoMap (topographic)
  - ESRI World Imagery (satellite)
- **Offline Support**: Map tiles cached for offline operation
- **Telemetry Tracking**: Monitor battery levels, GPS locations, and temperature for all contacts
- **BLE Communication**: Direct connection to MeshCore devices via Bluetooth

## Prerequisites

Before building the app, ensure you have:

- Flutter SDK 3.19.0 or higher
- Dart SDK 3.3.0 or higher
- Xcode 15+ (for iOS builds)
- Android Studio with Android SDK (for Android builds)
- CocoaPods (for iOS dependencies)

### Install Flutter

If you haven't installed Flutter yet:

```bash
# macOS/Linux
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

## Setup

1. **Clone the repository**:
   ```bash
   cd /path/to/meshcore-sar/meshcore_sar_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify setup**:
   ```bash
   flutter doctor
   ```
   Fix any issues reported by Flutter Doctor before proceeding.

## Building and Running

### iOS

#### Requirements
- macOS computer
- Xcode 15 or higher
- Apple Developer account (for physical device deployment)
- iOS device with iOS 13.0 or higher

#### Steps

1. **Open iOS folder in Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configure signing**:
   - In Xcode, select the Runner project
   - Go to "Signing & Capabilities"
   - Select your development team
   - Xcode will automatically handle provisioning

3. **Connect your iOS device** via USB

4. **Enable Developer Mode** on your iOS device:
   - Settings → Privacy & Security → Developer Mode → Enable

5. **Trust your Mac** on the iOS device when prompted

6. **Run the app**:
   ```bash
   # Run in debug mode
   flutter run

   # Or build release
   flutter build ios --release
   ```

7. **Install on device from Xcode**:
   - Select your device in Xcode
   - Click the "Run" button (▶️)

#### Common iOS Issues

**Problem**: "Runner has conflicting provisioning settings"
```bash
# Solution: Clean and rebuild
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

**Problem**: Bluetooth permissions not working
- Ensure `Info.plist` contains all required permission keys
- Check that permissions are requested at runtime

### Android

#### Requirements
- Android Studio installed
- Android SDK 21 (Android 5.0) or higher
- Physical Android device or emulator

#### Steps

1. **Enable Developer Options** on your Android device:
   - Settings → About Phone → Tap "Build Number" 7 times
   - Go back → Developer Options → Enable "USB Debugging"

2. **Connect your Android device** via USB and authorize the computer

3. **Verify device connection**:
   ```bash
   flutter devices
   ```

4. **Run the app**:
   ```bash
   # Run in debug mode
   flutter run

   # Or specify device
   flutter run -d <device-id>
   ```

5. **Build APK**:
   ```bash
   # Debug APK
   flutter build apk --debug

   # Release APK
   flutter build apk --release

   # App Bundle (for Play Store)
   flutter build appbundle --release
   ```

   The APK will be located at:
   - Debug: `build/app/outputs/flutter-apk/app-debug.apk`
   - Release: `build/app/outputs/flutter-apk/app-release.apk`

6. **Install APK manually**:
   ```bash
   # Install on connected device
   flutter install

   # Or use adb
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

#### Common Android Issues

**Problem**: Gradle build fails
```bash
# Solution: Clean and rebuild
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter build apk
```

**Problem**: Bluetooth permissions denied
- Ensure all Bluetooth permissions are in `AndroidManifest.xml`
- For Android 12+, request `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` at runtime

**Problem**: "Execution failed for task ':app:minifyReleaseWithR8'"
```bash
# Add to android/app/build.gradle
android {
    buildTypes {
        release {
            minifyEnabled false
        }
    }
}
```

## Running on Emulator/Simulator

### iOS Simulator

```bash
# List available simulators
flutter emulators

# Launch a simulator
flutter emulators --launch <simulator-id>

# Run app
flutter run
```

**Note**: BLE functionality will not work on iOS Simulator. Use a physical device for testing.

### Android Emulator

```bash
# List available emulators
flutter emulators

# Create new emulator in Android Studio:
# Tools → Device Manager → Create Virtual Device

# Launch emulator
flutter emulators --launch <emulator-id>

# Run app
flutter run
```

**Note**: BLE functionality requires specific emulator setup or physical device.

## Permissions

The app requires the following permissions:

### iOS (ios/Runner/Info.plist)
- `NSBluetoothAlwaysUsageDescription`: Bluetooth access for MeshCore devices
- `NSLocationWhenInUseUsageDescription`: Location access for map features

### Android (android/app/src/main/AndroidManifest.xml)
- `BLUETOOTH_SCAN`: Scan for BLE devices
- `BLUETOOTH_CONNECT`: Connect to BLE devices
- `ACCESS_FINE_LOCATION`: Required for BLE scanning
- `INTERNET`: Download map tiles

## Usage

1. **Connect to MeshCore Device**:
   - Tap "Connect" in the status bar
   - Select your MeshCore device from the scan results
   - Wait for connection confirmation

2. **View Messages**:
   - Messages tab shows all received messages
   - SAR marker messages are highlighted
   - Tap SAR marker to view on map

3. **Manage Contacts**:
   - Contacts tab shows team members, repeaters, and channels
   - Tap contact to view details
   - Use refresh button to request telemetry updates

4. **View Map**:
   - Map tab displays team locations and SAR markers
   - Tap layer selector to switch between map styles
   - Use zoom controls or pinch gestures
   - Tap markers for details
   - Tap items in bottom list to navigate

## SAR Marker Format

Messages can contain SAR markers using this format:
```
S:<emoji>:<latitude>,<longitude>
```

Examples:
- `S:🧑:46.0569,14.5058` - Found person
- `S:🔥:46.0570,14.5060` - Fire location
- `S:🏕️:46.0571,14.5062` - Staging area

## Architecture

- **Models**: Data structures for contacts, messages, markers, telemetry
- **Services**: BLE communication, tile caching, protocol parsing
- **Providers**: State management using Provider pattern
- **Screens**: UI components for messages, contacts, map
- **Widgets**: Reusable UI elements like map markers

## Dependencies

Key packages used:
- `flutter_blue_plus`: BLE communication
- `flutter_map`: Interactive mapping
- `flutter_map_tile_caching`: Offline map tiles
- `provider`: State management
- `latlong2`: GPS coordinate handling
- `permission_handler`: Runtime permissions

## Troubleshooting

### App crashes on launch
```bash
flutter clean
flutter pub get
flutter run
```

### BLE not working
- Ensure Bluetooth is enabled on device
- Check that all permissions are granted
- Verify MeshCore device is powered on and in range

### Map tiles not loading
- Check internet connection
- Verify tile URLs are accessible
- Clear tile cache and reload

### Build errors
```bash
# Complete clean rebuild
flutter clean
cd ios && pod deintegrate && pod install && cd ..
cd android && ./gradlew clean && cd ..
flutter pub get
flutter run
```

## License

This project is for Search and Rescue operations using MeshCore mesh network devices.

## Support

For issues related to:
- **Flutter**: https://flutter.dev/community
- **MeshCore Protocol**: https://github.com/meshcore-dev/meshcore.js
- **App Issues**: Open an issue in this repository
