# Installing Libraries for Arduino IDE

Since you're using Arduino IDE instead of PlatformIO, you need to manually install the required libraries.

## Required Libraries

1. **WebSockets** by Markus Sattler (Links2004)
2. **ArduinoJson** by Benoit Blanchon

## Installation Steps

### Method 1: Arduino Library Manager (Easiest)

1. **Open Arduino IDE**

2. **Install WebSockets Library:**
   - Go to: `Sketch` → `Include Library` → `Manage Libraries...`
   - Search for: `WebSockets`
   - Find: **"WebSockets" by Markus Sattler**
   - Click: `Install`
   - Wait for installation to complete

3. **Install ArduinoJson Library:**
   - Still in Library Manager
   - Search for: `ArduinoJson`
   - Find: **"ArduinoJson" by Benoit Blanchon**
   - Click: `Install` (install version 6.x, NOT version 7)
   - Wait for installation to complete

4. **Restart Arduino IDE**

5. **Verify Installation:**
   - Go to: `Sketch` → `Include Library`
   - You should see:
     - `WebSockets`
     - `ArduinoJson`

6. **Open Your Sketch:**
   - Open: `F:\Infinity\02_Work\01_Projects\AT-for-VI\audio-player\src\main.cpp`
   - Click: `Verify` (checkmark button)
   - Should compile successfully!

### Method 2: Manual Installation

If Library Manager doesn't work:

#### For WebSockets:

1. Download: https://github.com/Links2004/arduinoWebSockets/archive/master.zip
2. Extract the ZIP file
3. Rename folder from `arduinoWebSockets-master` to `WebSockets`
4. Move to: `C:\Users\CortexnGrey\Documents\Arduino\libraries\WebSockets`
5. Restart Arduino IDE

#### For ArduinoJson:

1. Download: https://github.com/bblanchon/ArduinoJson/releases (get version 6.x)
2. Extract the ZIP file
3. Rename folder to `ArduinoJson`
4. Move to: `C:\Users\CortexnGrey\Documents\Arduino\libraries\ArduinoJson`
5. Restart Arduino IDE

## Verification

After installation, this code should work:

```cpp
#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>

void setup() {
  Serial.begin(115200);
  Serial.println("Libraries loaded successfully!");
}

void loop() {}
```

## Common Issues

### Issue: "WebSocketsServer.h: No such file or directory"
**Solution:** Library not installed. Follow Method 1 above.

### Issue: "WiFi.h: No such file or directory"
**Solution:** ESP32 board not selected. Go to `Tools` → `Board` → `ESP32 Arduino` → `ESP32 Dev Module`

### Issue: "ArduinoJson.h version error"
**Solution:** Install ArduinoJson version 6.x (not 7.x). Our code uses v6 API.

### Issue: Library Manager is empty or slow
**Solution:**
1. Check internet connection
2. Go to `File` → `Preferences`
3. Click `Additional Board Manager URLs`
4. Ensure ESP32 URL is present: `https://dl.espressif.com/dl/package_esp32_index.json`
5. Click OK, restart IDE
6. Go to `Tools` → `Board` → `Boards Manager`
7. Install **ESP32** by Espressif Systems

## After Installation

1. **Select Board:**
   - `Tools` → `Board` → `ESP32 Arduino` → `ESP32 Dev Module`

2. **Select Port:**
   - `Tools` → `Port` → `COM3` (or your ESP32's port)

3. **Upload:**
   - Click `Upload` (arrow button)

4. **Monitor:**
   - `Tools` → `Serial Monitor`
   - Set baud rate to: `115200`

You should see:
```
=====================================
  Audio Remote ESP32 - WiFi Edition
  Version 2.0.0
=====================================

Starting Access Point mode...
SSID: AudioRemote_ESP32
Access Point started successfully!
IP Address: 192.168.4.1
```

## Alternative: Use PlatformIO

PlatformIO automatically installs all libraries. Much easier!

See: `PLATFORMIO_SETUP.md` for instructions.

**Advantages:**
- ✅ Auto-installs libraries
- ✅ No manual setup
- ✅ Better dependency management
- ✅ Integrated in VS Code
- ✅ Faster compilation

To use PlatformIO:
```powershell
cd F:\Infinity\02_Work\01_Projects\AT-for-VI\audio-player
code .
```

Then click Build button in VS Code bottom toolbar.
