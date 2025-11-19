# PlatformIO Setup for ESP32 Audio Remote

This project is configured for **PlatformIO** development with ESP32 WROOM-32 board.

## Prerequisites

1. **Visual Studio Code** with **PlatformIO IDE** extension installed
2. **ESP32 WROOM-32** board
3. **USB cable** for programming

## Project Structure

```
audio-player/
├── platformio.ini          # PlatformIO configuration
├── src/
│   └── main.cpp           # Main firmware code (formerly .ino)
└── .gitignore
```

## Getting Started

### 1. Install PlatformIO

If you haven't already:
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for "PlatformIO IDE"
4. Click Install
5. Reload VS Code when prompted

### 2. Open Project in PlatformIO

```bash
cd F:\Infinity\02_Work\01_Projects\AT-for-VI\audio-player
code .
```

Or from VS Code:
- File → Open Folder → Select `audio-player` folder
- PlatformIO will automatically detect `platformio.ini`

### 3. Build the Project

Click the **Build** button (checkmark icon) in the PlatformIO toolbar at the bottom, or:

```bash
pio run
```

### 4. Upload to ESP32

1. Connect your ESP32 WROOM-32 via USB
2. Click the **Upload** button (right arrow icon) in PlatformIO toolbar, or:

```bash
pio run --target upload
```

PlatformIO will auto-detect your COM port. If needed, specify in `platformio.ini`:
```ini
upload_port = COM3  ; Change to your port
```

### 5. Monitor Serial Output

Click the **Serial Monitor** button (plug icon) or:

```bash
pio device monitor
```

To enable debug output, uncomment `#define DEBUG` in `src/main.cpp`.

## Configuration

### Board Settings (platformio.ini)

- **Board**: ESP32 Dev Module (esp32dev)
- **Platform**: Espressif 32
- **Framework**: Arduino
- **CPU Frequency**: 240 MHz
- **Flash Frequency**: 80 MHz
- **Upload Speed**: 921600 baud
- **Monitor Speed**: 115200 baud

### Troubleshooting

#### Upload Failed
1. Check USB cable connection
2. Press and hold **BOOT** button on ESP32 during upload
3. Try lower upload speed in `platformio.ini`:
   ```ini
   upload_speed = 115200
   ```

#### Port Not Found
- Windows: Check Device Manager → Ports (COM & LPT)
- Install CP2102 or CH340 drivers if needed
- Manually set port in `platformio.ini`:
  ```ini
  upload_port = COM3
  ```

#### Compilation Errors
- PlatformIO automatically manages ESP32 BLE libraries
- No need to install ArduinoBLE or other conflicting libraries
- Clean build: `pio run --target clean`

## PlatformIO Commands

```bash
# Build project
pio run

# Upload firmware
pio run --target upload

# Upload and monitor
pio run --target upload --target monitor

# Clean build files
pio run --target clean

# Update platforms/libraries
pio update

# List connected devices
pio device list
```

## Features

- ✅ ESP32 BLE built-in (no external dependencies)
- ✅ Auto-detection of COM ports
- ✅ Fast upload speeds (921600 baud)
- ✅ Serial monitor with timestamps
- ✅ Optimized build flags for ESP32
- ✅ Debug configuration ready

## GPIO Pin Configuration

All pins are RTC-compatible for deep sleep wake-up:

- **GPIO 0**: Play/Pause (also BOOT button)
- **GPIO 2**: Next Track
- **GPIO 4**: Previous Track
- **GPIO 12**: Volume Up
- **GPIO 13**: Volume Down
- **GPIO 14**: Speed Cycle
- **GPIO 15**: Repeat Cycle
- **GPIO 27**: Note/Bookmark
- **GPIO 21**: Status LED

## Next Steps

1. Build and upload the firmware to your ESP32
2. Power cycle the device (disconnect/reconnect USB)
3. Look for "AudioRemote" in Bluetooth devices
4. Pair with the Flutter app
5. Test button functionality

For Flutter app setup, see `flutter_app/README.md`.

## Resources

- [PlatformIO Documentation](https://docs.platformio.org/)
- [ESP32 Arduino Core](https://github.com/espressif/arduino-esp32)
- [Project Repository](https://github.com/athulkannan2000/audio-player)
