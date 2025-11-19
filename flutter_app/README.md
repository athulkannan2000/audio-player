# Flutter Audio Player with ESP32 Remote Control

A feature-rich audio player with time-linked note-taking capabilities and hardware remote control via ESP32 BLE.

## Features

- 🎵 **Full Audio Playback**: Play/pause, seek, speed control (0.5x-2x), volume, shuffle, and repeat
- 📝 **Time-Linked Notes**: Attach timestamped notes to specific audio moments
- 🎮 **ESP32 BLE Remote**: Hardware remote control with 8 buttons for hands-free operation
- 💾 **Offline-First**: All features work without internet connectivity
- 🔄 **Cross-Platform**: Supports Android and iOS

## Prerequisites

- Flutter SDK 3.0 or higher
- Dart 3.0 or higher
- Android Studio / Xcode for mobile development
- ESP32 remote (optional, but recommended)

## Installation

### 1. Clone the Repository

```bash
cd audio-player/flutter_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

For Android:
```bash
flutter run
```

For iOS:
```bash
flutter run
```

For development with hot reload:
```bash
flutter run --debug
```

## Project Structure

```
lib/
├── main.dart                   # App entry point
├── models/                     # Data models
│   ├── playback_state.dart     # Playback state model
│   ├── note.dart               # Note model
│   └── ble_command.dart        # BLE command model
├── services/                   # Business logic
│   ├── audio_service.dart      # Audio playback service
│   ├── ble_service.dart        # BLE communication service
│   └── database_service.dart   # SQLite database service
├── providers/                  # Riverpod providers
│   └── app_providers.dart      # State management providers
├── screens/                    # UI screens
│   ├── home_screen.dart        # Main screen with tabs
│   ├── ble_pairing_screen.dart # BLE device pairing
│   └── settings_screen.dart    # App settings
└── widgets/                    # Reusable widgets
    ├── player_controls.dart    # Audio player UI
    └── notes_list.dart         # Notes list UI
```

## Configuration

### Android

The app requires the following permissions (already configured in `AndroidManifest.xml`):

- Bluetooth permissions (BLUETOOTH, BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
- Location permission (required for BLE scanning on Android < 12)
- Storage permissions (for audio file access)
- Foreground service (for background audio playback)

### iOS

The app requires the following permissions (already configured in `Info.plist`):

- Bluetooth usage description
- Background modes (audio, bluetooth-central)
- Music library access

## Usage

### Playing Audio

1. Launch the app
2. Tap the "Select Audio File" button
3. Choose an audio file from your device
4. Use the playback controls to play/pause, seek, adjust volume and speed

### Creating Notes

1. While audio is playing, tap the floating action button (+) on the Notes tab
2. Or press the Note button on your ESP32 remote
3. Enter your note text
4. The note will be saved with the current timestamp

### Pairing ESP32 Remote

1. Tap the Bluetooth icon in the app bar
2. Tap "Start Scanning"
3. Select your "AudioRemote" device from the list
4. Tap "Connect"

Once connected, you can use the remote buttons:
- Play/Pause: Toggle playback
- Next/Previous: Skip forward/backward 15 seconds
- Volume +/-: Adjust volume
- Speed: Cycle playback speed
- Repeat: Cycle repeat modes
- Note: Create timestamped note

## Dependencies

Key packages used:

- **flutter_riverpod**: State management
- **just_audio**: Audio playback engine
- **audio_service**: Background audio support
- **flutter_blue_plus**: BLE communication
- **sqflite**: Local database for notes
- **file_picker**: Audio file selection

## Development

### Running Tests

```bash
flutter test
```

### Building for Release

Android:
```bash
flutter build apk --release
```

iOS:
```bash
flutter build ios --release
```

### Code Generation

If you modify JSON serialization:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Troubleshooting

### Bluetooth Not Working

- Ensure Bluetooth is enabled on your device
- Grant all required permissions when prompted
- On Android 12+, location services must be enabled for BLE scanning
- Restart the app if connection fails

### Audio Not Playing

- Check that the audio file format is supported (MP3, M4A, WAV)
- Ensure storage permissions are granted
- Try a different audio file

### Notes Not Saving

- Check that storage permissions are granted
- Ensure there's sufficient storage space on your device

## Contributing

See the main project CONTRIBUTING.md for guidelines.

## License

MIT License - See LICENSE file in the root directory

## Related Documentation

- [Project Overview](../README.md)
- [Audio Player Architecture](../Audio_player.md)
- [ESP32 Remote Integration](../Remote_integration.md)
- [ESP32 Firmware](../AudioRemote_ESP32.ino)

## Support

For issues and questions:
- GitHub Issues: https://github.com/athulkannan2000/audio-player/issues
- Documentation: See markdown files in parent directory

---

**Built with Flutter and ❤️ for accessible audio learning**
