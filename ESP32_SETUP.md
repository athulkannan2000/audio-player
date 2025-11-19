# ESP32 BLE Remote Setup Guide

## Hardware Requirements
- **ESP32-WROOM-32** or compatible ESP32 development board (NOT Arduino Uno/Nano/Mega)
- 8 tactile buttons (connected to the specified GPIO pins)
- Optional: LED on GPIO 21 for status indication
- Optional: CR2032 battery holder with voltage regulator

## Software Requirements

### 1. Arduino IDE Setup
1. Install Arduino IDE (version 1.8.x or 2.x)
2. Install ESP32 board support:
   - Open Arduino IDE
   - Go to **File > Preferences**
   - Add this URL to "Additional Board Manager URLs":
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Go to **Tools > Board > Boards Manager**
   - Search for "esp32"
   - Install "**esp32 by Espressif Systems**" (version 2.0.0 or later)

### 2. Important: Remove Conflicting Libraries
If you get compilation errors about multiple BLE libraries, you need to remove the conflicting ones:

**Windows:**
- Navigate to: `C:\Users\<YourUsername>\Documents\Arduino\libraries\`
- **DELETE** these folders if they exist:
  - `ArduinoBLE`
  - `ESP32_BLE_Arduino` (if it's a separate manual install)

**Mac/Linux:**
- Navigate to: `~/Documents/Arduino/libraries/`
- Delete the same folders

**The correct BLE library is built into the ESP32 board package** - you don't need to install anything extra!

### 3. Board Selection
In Arduino IDE:
1. Go to **Tools > Board**
2. Select **ESP32 Arduino > ESP32 Dev Module** (or your specific ESP32 board)
3. Set these parameters:
   - **Upload Speed**: 921600
   - **CPU Frequency**: 240MHz (WiFi/BT)
   - **Flash Frequency**: 80MHz
   - **Flash Mode**: QIO
   - **Flash Size**: 4MB (32Mb)
   - **Partition Scheme**: Default 4MB with spiffs
   - **Core Debug Level**: None (or Info for debugging)
   - **Erase All Flash Before Sketch Upload**: Disabled

### 4. Port Selection
- Connect your ESP32 via USB
- Go to **Tools > Port** and select the COM port for your ESP32
  - Windows: Usually COM3, COM4, etc.
  - Mac: Usually /dev/cu.usbserial-XXXX
  - Linux: Usually /dev/ttyUSB0

## Compilation

### First Time Compilation
1. Open `AudioRemote_ESP32.ino` in Arduino IDE
2. Click **Verify/Compile** (checkmark icon)
3. Wait for compilation to complete (may take 1-2 minutes first time)
4. If successful, you'll see "Done compiling"

### Common Compilation Errors and Fixes

#### Error: "BLEDevice.h: No such file or directory"
**Solution**: Make sure you selected an ESP32 board (not Arduino board)

#### Error: "Multiple libraries found for BLEDevice.h"
**Solution**: Remove the conflicting libraries as described in step 2 above

#### Error: "'ringbuf_type_t' has not been declared"
**Solution**: Update ESP32 board package to latest version via Boards Manager

#### Error: "class BLEDescriptor redefinition"
**Solution**: Remove ArduinoBLE library - it conflicts with ESP32 BLE library

## Upload to ESP32

1. Make sure ESP32 is connected via USB
2. Select correct COM port
3. Click **Upload** (right arrow icon)
4. During upload, you may need to:
   - Hold the **BOOT** button on ESP32
   - Press **RESET** button while holding BOOT
   - Release both buttons
5. Wait for upload to complete
6. Open **Serial Monitor** (if DEBUG is enabled) to see status messages

## Testing

### With DEBUG Enabled
1. Uncomment `#define DEBUG` at the top of the sketch
2. Upload the sketch
3. Open Serial Monitor (Tools > Serial Monitor)
4. Set baud rate to **115200**
5. Press RESET button on ESP32
6. You should see initialization messages

### Without DEBUG (Production)
1. Make sure `// #define DEBUG` is commented out
2. Upload the sketch
3. LED will blink twice on power-up
4. Device will appear as "AudioRemote" in BLE scan

## GPIO Pin Mapping

| Button Function | GPIO Pin | Notes |
|----------------|----------|-------|
| Play/Pause     | GPIO 0   | Boot button, wake-up capable |
| Next           | GPIO 2   | Built-in LED on some boards |
| Previous       | GPIO 4   | RTC GPIO |
| Volume Up      | GPIO 12  | RTC GPIO |
| Volume Down    | GPIO 13  | RTC GPIO |
| Speed          | GPIO 14  | RTC GPIO |
| Repeat         | GPIO 15  | RTC GPIO |
| Note           | GPIO 27  | RTC GPIO |
| Status LED     | GPIO 21  | Non-RTC GPIO |

## Power Consumption

- **Active (connected)**: ~80-100mA
- **Active (advertising)**: ~60-80mA
- **Deep Sleep**: <10µA
- **Wake-up time**: <100ms

## Troubleshooting

### ESP32 not detected
1. Install USB-to-Serial driver (CP210x or CH340)
2. Try different USB cable (must be data cable, not charge-only)
3. Try different USB port

### Upload fails
1. Hold BOOT button during upload
2. Lower upload speed (115200 instead of 921600)
3. Press RESET after upload completes

### BLE not working
1. Ensure ESP32 board is selected (not Arduino)
2. Ensure correct BLE library is being used
3. Check that ArduinoBLE is not installed

## Additional Resources

- [ESP32 Arduino Core Documentation](https://docs.espressif.com/projects/arduino-esp32/)
- [ESP32 BLE Examples](https://github.com/espressif/arduino-esp32/tree/master/libraries/BLE/examples)
- [ESP32 Technical Reference](https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf)
