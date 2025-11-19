# Flutter App Setup Guide

This guide will help you set up and run the Flutter audio player application.

## Prerequisites

### Required Software

1. **Flutter SDK 3.0+**
   - Download from: https://flutter.dev/docs/get-started/install
   - Follow the installation guide for your OS (Windows/macOS/Linux)
   - Verify installation: `flutter doctor`

2. **Development Environment**
   
   For Android:
   - Android Studio (recommended) or VS Code
   - Android SDK (API level 21 or higher)
   - Android device or emulator
   
   For iOS (macOS only):
   - Xcode 14 or higher
   - CocoaPods: `sudo gem install cocoapods`
   - iOS device or simulator

3. **Git** (to clone the repository)

## Step-by-Step Setup

### 1. Verify Flutter Installation

Open a terminal and run:

```bash
flutter doctor
```

This will check your installation and show any missing requirements. Fix any issues shown.

### 2. Navigate to Flutter App Directory

```bash
cd C:\Users\athul\Athul\Projects\AT_for_VI\audio-player\flutter_app
```

### 3. Install Dependencies

```bash
flutter pub get
```

This will download all required packages (may take a few minutes).

### 4. Platform-Specific Setup

#### Android Setup

1. Open Android Studio
2. Open the `android` folder as a project
3. Wait for Gradle sync to complete
4. Connect an Android device or start an emulator

#### iOS Setup (macOS only)

1. Navigate to ios folder:
   ```bash
   cd ios
   ```

2. Install CocoaPods dependencies:
   ```bash
   pod install
   ```

3. Open `Runner.xcworkspace` in Xcode
4. Select your development team in signing settings
5. Connect an iOS device or start a simulator

### 5. Run the App

#### Quick Start (Debug Mode)

```bash
flutter run
```

This will:
- Build the app
- Install it on your connected device/emulator
- Launch with hot reload enabled

#### Specific Platform

For Android:
```bash
flutter run -d android
```

For iOS:
```bash
flutter run -d ios
```

#### Release Build

For Android APK:
```bash
flutter build apk --release
```

For iOS:
```bash
flutter build ios --release
```

## Permissions Setup

### Android Permissions

The app will request these permissions at runtime:
- **Bluetooth**: To connect to ESP32 remote
- **Location**: Required for BLE scanning on Android < 12
- **Storage**: To access audio files

Grant all permissions when prompted.

### iOS Permissions

Permissions are requested when:
- Opening Bluetooth settings (first time)
- Selecting audio files (first time)

Tap "Allow" when prompted.

## First Run Guide

### 1. Launch the App

The app will open to the Player screen.

### 2. Load an Audio File

1. Tap "Select Audio File"
2. Navigate to an audio file on your device
3. Select the file
4. The audio will load and start playing

### 3. Test Playback Controls

- **Play/Pause**: Tap the large play button
- **Seek**: Drag the slider
- **Skip**: Use forward/backward buttons (15s increments)
- **Volume**: Use +/- buttons
- **Speed**: Tap speed button to cycle (1.0x → 1.25x → 1.5x → 2.0x → 0.75x)

### 4. Create a Note

1. Switch to "Notes" tab
2. Tap the floating "+" button
3. Enter your note text
4. Tap "Save"
5. The note appears with a timestamp

### 5. Pair ESP32 Remote (Optional)

1. Power on your ESP32 remote
2. Tap the Bluetooth icon (top-right)
3. Tap "Start Scanning"
4. Look for "AudioRemote" device
5. Tap "Connect"
6. Test remote buttons

## Troubleshooting

### "flutter: command not found"

- Ensure Flutter is added to your PATH
- Restart your terminal
- Run: `export PATH="$PATH:[FLUTTER_INSTALL_PATH]/bin"`

### Gradle Build Errors (Android)

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### CocoaPods Errors (iOS)

```bash
cd ios
pod repo update
pod install
cd ..
flutter clean
flutter run
```

### "No devices found"

- **Android**: 
  - Enable USB debugging on your phone
  - Install USB drivers for your device
  - Try `flutter devices` to list available devices

- **iOS**:
  - Trust the computer on your iPhone
  - Open Xcode and go to Window → Devices
  - Verify device is recognized

### Bluetooth Not Working

1. Ensure Bluetooth is enabled on your device
2. On Android 12+, enable location services
3. Grant all permissions in app settings
4. Restart the app

### Audio File Not Playing

- Supported formats: MP3, M4A, WAV, AAC
- Try a different file
- Check storage permissions

### Hot Reload Not Working

- Press 'r' in the terminal to manually reload
- Press 'R' for full restart
- Or use the hot reload button in your IDE

## Development Tips

### Hot Reload

While the app is running, edit any Dart file and save. The app will update instantly.

Shortcuts:
- `r` - Hot reload
- `R` - Hot restart
- `q` - Quit
- `d` - Detach (keep app running)

### Debugging

1. Use VS Code or Android Studio debugger
2. Add breakpoints in your code
3. Run in debug mode: `flutter run --debug`
4. View logs: `flutter logs`

### Viewing Logs

```bash
flutter logs
```

Or filter for specific tags:
```bash
flutter logs --tag="AudioService"
```

### Code Formatting

```bash
flutter format lib/
```

### Analyzing Code

```bash
flutter analyze
```

## IDE Setup

### VS Code

Recommended extensions:
- Flutter
- Dart
- Flutter Widget Snippets

### Android Studio

Install:
- Flutter plugin
- Dart plugin

## Building for Production

### Android (APK)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android (App Bundle)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS

1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select your provisioning profile
3. Product → Archive
4. Distribute to App Store or TestFlight

## Testing

### Run Unit Tests

```bash
flutter test
```

### Run Integration Tests

```bash
flutter drive --target=test_driver/app.dart
```

## Performance Profiling

```bash
flutter run --profile
```

Then use Flutter DevTools to analyze performance.

## Getting Help

1. Check Flutter documentation: https://flutter.dev/docs
2. Check package documentation on pub.dev
3. See main project README: `../README.md`
4. Open an issue on GitHub

## Next Steps

- Read [Audio_player.md](../Audio_player.md) for architecture details
- Read [Remote_integration.md](../Remote_integration.md) for ESP32 integration
- Flash the ESP32 firmware: [AudioRemote_ESP32.ino](../AudioRemote_ESP32.ino)
- Customize the app for your needs

---

**Happy coding! 🎵**
