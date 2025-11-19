# Audio Player with ESP32 Remote Control

A cross-platform audio player system with integrated note-taking functionality and hardware remote control via ESP32 and Bluetooth Low Energy (BLE).

## 🎯 Overview

This project combines a feature-rich audio player with time-linked note-taking capabilities and hands-free hardware control. Users can pause playback and attach text notes to specific timestamps (e.g., "2:15 – Important concept about ATP synthesis"), while controlling playback through a custom ESP32-based remote.

### Key Features

- **🎵 Full-featured Audio Playback**: Play/pause, seek, speed control (0.5x-2x), volume, shuffle, and repeat modes
- **📝 Time-linked Notes**: Attach timestamped notes to audio for learning, podcasting, and content review
- **🎮 Hardware Remote Control**: ESP32-based BLE remote with 8 tactile buttons for hands-free operation
- **♿ Accessibility**: Designed for eyes-free operation, driving safety, and users with motor impairments
- **🔋 Ultra-Low Power**: 6-10 months battery life on CR2032 coin cell
- **💾 Offline-First**: All features work without internet connectivity
- **🔄 Cross-Platform**: Mobile (iOS/Android via Flutter), Web, and extensible architecture

## 📁 Repository Structure

```
VI_AT/
├── Audio_player.md              # Core audio player architecture & specifications
├── Remote_integration.md        # ESP32 hardware remote integration guide
├── AudioRemote_ESP32.ino        # ESP32 firmware (Arduino sketch)
├── flutter_app/                 # Flutter mobile application (to be created)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/
│   │   │   ├── ble_manager.dart
│   │   │   └── audio_service.dart
│   │   ├── providers/
│   │   │   └── playback_provider.dart
│   │   └── models/
│   │       └── note_model.dart
│   └── pubspec.yaml
├── hardware/                    # Hardware design files (to be added)
│   ├── schematics/
│   ├── pcb/
│   └── enclosure/              # 3D printable STL files
├── docs/                       # Additional documentation
└── README.md                   # This file
```

## 🚀 Quick Start

### ESP32 Remote Setup

#### Hardware Requirements
- ESP32-WROOM-32 or compatible module
- 8 tactile push buttons
- CR2032 battery + holder
- Optional: Status LED, 3D-printed enclosure

#### Pin Configuration
| Button | GPIO | Function |
|--------|------|----------|
| Play/Pause | 15 | Toggle playback |
| Next | 2 | Skip forward 15s |
| Previous | 4 | Skip backward 15s |
| Volume+ | 16 | Increase volume |
| Volume- | 17 | Decrease volume |
| Speed | 5 | Cycle speed presets |
| Repeat | 18 | Cycle repeat modes |
| Note | 19 | Take timestamped note |
| LED Status | 21 | Connection indicator |

#### Flashing Firmware

1. **Install Arduino IDE 2.x**
   - Download from [arduino.cc](https://www.arduino.cc/en/software)

2. **Install ESP32 Board Support**
   ```
   File → Preferences → Additional Board Manager URLs:
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
   Then: Tools → Board → Boards Manager → Search "ESP32" → Install

3. **Install Dependencies**
   - All required libraries (BLEDevice, BLEServer) are included in ESP32 core

4. **Configure & Upload**
   - Open `AudioRemote_ESP32.ino` in Arduino IDE
   - Select: Tools → Board → ESP32 Dev Module
   - Select your COM port
   - Click Upload (⬆️)

5. **Testing**
   - Open Serial Monitor (115200 baud) if DEBUG is enabled
   - Press any button – LED should blink
   - Use nRF Connect app to verify BLE advertising

### Mobile App Setup (Flutter)

✅ **Flutter app is now available!** See [`flutter_app/`](flutter_app/) directory.

#### Prerequisites
- Flutter SDK 3.x+
- Android Studio / Xcode (for mobile development)
- Device with BLE support

#### Quick Setup
```bash
cd flutter_app
flutter pub get
flutter run
```

For detailed instructions, see:
- [Flutter App README](flutter_app/README.md)
- [Setup Guide](flutter_app/SETUP_GUIDE.md)
- [Quick Start](flutter_app/QUICK_START.txt)

## 🏗️ Architecture

### Audio Player State Contract

All state is serializable (JSON) for debugging and persistence:

```json
{
  "playback": {
    "isPlaying": true,
    "duration_ms": 3600000,
    "position_ms": 45000,
    "volume": 0.9,
    "speed": 1.25,
    "isShuffling": false,
    "isRepeating": "off",
    "progress": 0.0125
  },
  "notes": [
    {
      "id": "uuid-v4",
      "timestamp_ms": 135000,
      "note_text": "Important concept",
      "created_at": "2025-10-29T12:34:56Z"
    }
  ]
}
```

### BLE Communication Protocol

**Service UUID**: `0000A000-0000-1000-8000-00805F9B34FB`  
**Characteristic UUID**: `0000A001-0000-1000-8000-00805F9B34FB`

**Command Format** (ESP32 → Mobile):
```json
{
  "cmd": "play_pause",
  "seq": 42
}
```

**Supported Commands**:
- `play_pause`, `next`, `prev`
- `volume_up`, `volume_down`
- `speed_cycle`, `repeat_cycle`
- `note` (triggers timestamped note input)

### Power Management

- **Deep Sleep**: <10µA when idle >10s
- **Active BLE**: ~40mA during transmission (brief bursts)
- **Estimated Battery Life**: 6-10 months on CR2032 (220mAh)

## 📋 Development Roadmap

- [x] **Phase 1**: Core audio playback architecture (documented)
- [x] **Phase 1.5**: ESP32 remote prototype (firmware complete)
- [ ] **Phase 2**: Flutter app with BLE integration
- [ ] **Phase 2**: Note-taking with local persistence
- [ ] **Phase 3**: Cloud sync, dark mode, accessibility audit
- [ ] **Phase 4**: Transcription search, collaborative notes

## 🧪 Testing

### ESP32 Firmware Testing

**With nRF Connect (Mobile App)**:
1. Install nRF Connect (iOS/Android)
2. Scan for "AudioRemote" device
3. Connect and explore services
4. Subscribe to characteristic `0000A001-...`
5. Press buttons on remote – observe JSON commands

**Latency Test**:
- Target: <300ms from button press to mobile action
- Method: Oscilloscope on GPIO + screen recording at 240fps

### Mobile App Testing (Coming Soon)
- Unit tests for state management
- Integration tests: play → seek → note creation
- BLE mock for CI/CD

## 🛠️ Hardware Bill of Materials (BOM)

| Component | Quantity | Unit Cost | Notes |
|-----------|----------|-----------|-------|
| ESP32-WROOM-32 | 1 | $2.50 | Or ESP32-C3 for lower cost |
| Tactile switches | 8 | $0.10 ea | 100k+ cycle rated |
| CR2032 battery | 1 | $0.40 | 220mAh, 3V |
| Battery holder | 1 | $0.20 | Through-hole or SMD |
| RGB LED (optional) | 1 | $0.15 | Status indicator |
| Resistors/caps | - | $0.15 | Debounce, LED current limit |
| PCB | 1 | $1.50 | Custom (or perfboard) |
| 3D-printed case | 1 | $1.00 | PLA/PETG filament |
| **Total** | - | **~$7.00** | At scale (100+ units) |

## 🤝 Contributing

Contributions welcome! Areas of interest:
- Flutter mobile app implementation
- Hardware enclosure designs (CAD/STL files)
- Additional platform support (React Native, web)
- Localization and accessibility improvements

### Development Setup

1. Fork this repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Related Resources

- [ESP32 Arduino Core](https://github.com/espressif/arduino-esp32)
- [Flutter Blue Plus](https://pub.dev/packages/flutter_blue_plus)
- [just_audio](https://pub.dev/packages/just_audio) - Audio playback for Flutter
- [audio_service](https://pub.dev/packages/audio_service) - Background audio

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/VI_AT/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/VI_AT/discussions)
- **Documentation**: See `/docs` folder and markdown files

## 🙏 Acknowledgments

- ESP32 community for BLE examples
- Flutter team for excellent cross-platform framework
- Contributors to just_audio and flutter_blue_plus packages

---

**Built with ❤️ for accessible, hands-free audio learning**

*Project Status: Active Development | Version: 1.0.0 | Last Updated: October 30, 2025*
