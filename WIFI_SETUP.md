# ESP32 WiFi Remote - Setup Guide

## 🔄 Migration from BLE to WiFi

Your ESP32 remote now uses **WiFi + WebSocket** instead of Bluetooth for more reliable communication!

## ✨ Benefits of WiFi

✅ **More Reliable**: No BLE pairing issues  
✅ **Longer Range**: WiFi covers more distance than Bluetooth  
✅ **Faster**: Lower latency for button presses  
✅ **Easier Setup**: Simple WiFi connection instead of BLE pairing  
✅ **Web Interface**: Can access from any device with a browser

## 🔧 Hardware Requirements

- ESP32-WROOM-32 or ESP32-DevKit
- 8 tactile buttons (same as before)
- Optional LED on GPIO 21
- **USB Power Recommended** (WiFi uses more power than BLE)

## ⚙️ Configuration

### WiFi Mode Selection

Open `src/main.cpp` and choose your mode:

#### **Option 1: Access Point Mode (Recommended)**
ESP32 creates its own WiFi network - no router needed!

```cpp
#define WIFI_MODE_AP true  // ✅ Already set to true

// Default settings:
#define AP_SSID           "AudioRemote_ESP32"
#define AP_PASSWORD       "audio12345"  // Change if desired
```

**Advantages:**
- No existing WiFi needed
- Works anywhere
- Direct connection
- No router configuration

#### **Option 2: Station Mode**
ESP32 connects to your existing WiFi network.

```cpp
#define WIFI_MODE_AP false  // ❌ Set to false for Station mode

// Update these:
#define STA_SSID          "YourWiFiName"
#define STA_PASSWORD      "YourWiFiPassword"
```

**Advantages:**
- All devices on same network
- Can use internet on phone simultaneously
- Remote access possible

## 📱 Build and Upload

### 1. Open Project in VS Code
```powershell
cd F:\Infinity\02_Work\01_Projects\AT-for-VI\audio-player
code .
```

### 2. Install PlatformIO Dependencies
PlatformIO will automatically install:
- `WebSockets` library (by Links2004)
- `ArduinoJson` library (by Benoit Blanchon)

### 3. Build the Project
Click the **Build** button (checkmark) or press `Ctrl+Alt+B`

### 4. Upload to ESP32
1. Connect ESP32 via USB
2. Click the **Upload** button (arrow) or press `Ctrl+Alt+U`

### 5. Monitor Serial Output
Click the **Serial Monitor** button (plug icon) or press `Ctrl+Alt+S`

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
WebSocket Port: 81

Connect your phone to this WiFi network:
  SSID: AudioRemote_ESP32
  Password: audio12345
  WebSocket URL: ws://192.168.4.1:81

Setup Complete
Ready for connections!
```

## 📲 Connect from Flutter App

### Update Flutter App

You'll need to update your Flutter app to use WebSocket instead of BLE:

**1. Add WebSocket dependency to `pubspec.yaml`:**
```yaml
dependencies:
  web_socket_channel: ^2.4.0
```

**2. Replace BLE service with WebSocket:**

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  String remoteIp = '192.168.4.1';  // ESP32 AP mode IP
  int remotePort = 81;
  
  Future<bool> connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$remoteIp:$remotePort'),
      );
      
      // Listen for messages
      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          handleCommand(data);
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
      );
      
      return true;
    } catch (e) {
      print('Connection failed: $e');
      return false;
    }
  }
  
  void handleCommand(Map<String, dynamic> data) {
    final cmd = data['cmd'];
    final seq = data['seq'];
    
    switch (cmd) {
      case 'play_pause':
        // Handle play/pause
        break;
      case 'next':
        // Handle next track
        break;
      case 'prev':
        // Handle previous track
        break;
      case 'volume_up':
        // Handle volume up
        break;
      case 'volume_down':
        // Handle volume down
        break;
      case 'speed_cycle':
        // Handle speed change
        break;
      case 'repeat_cycle':
        // Handle repeat mode
        break;
      case 'note':
        // Handle note/bookmark
        final timestamp = data['timestamp'];
        break;
      case 'low_battery':
        // Show low battery warning
        final voltage = data['voltage'];
        break;
      case 'status':
        // Connection status
        final battery = data['battery'];
        final rssi = data['rssi'];
        break;
    }
  }
  
  void disconnect() {
    _channel?.sink.close();
  }
}
```

**3. Update connection UI:**

```dart
// Instead of BLE scanning, show WiFi connection:
ElevatedButton(
  onPressed: () async {
    // For AP Mode:
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect to ESP32'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('1. Connect to WiFi:'),
            Text('   SSID: AudioRemote_ESP32'),
            Text('   Password: audio12345'),
            SizedBox(height: 10),
            Text('2. Return to app and tap Connect'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = WebSocketService();
              bool connected = await service.connect();
              if (connected) {
                // Navigate to home screen
              }
            },
            child: Text('Connect'),
          ),
        ],
      ),
    );
  },
  child: Text('Connect to Remote'),
)
```

## 🧪 Testing

### 1. Connect to WiFi Network

**AP Mode:**
- Look for WiFi network: `AudioRemote_ESP32`
- Connect with password: `audio12345`
- Your phone is now connected to the ESP32!

**Station Mode:**
- ESP32 connects to your existing WiFi
- Check Serial Monitor for IP address (e.g., `192.168.1.100`)
- Update Flutter app with this IP

### 2. Test WebSocket Connection

You can test with a WebSocket client tool or browser:

**Using JavaScript Console** (Chrome/Edge):
```javascript
// Open browser console (F12)
const ws = new WebSocket('ws://192.168.4.1:81');

ws.onopen = () => {
  console.log('Connected!');
  ws.send(JSON.stringify({cmd: 'ping'}));
};

ws.onmessage = (event) => {
  console.log('Received:', event.data);
};
```

### 3. Test Buttons

Press any button on your ESP32 remote. You should see:
- LED blinks briefly
- Serial Monitor shows: `Sent: {"cmd":"play_pause","seq":1,"timestamp":12345}`
- Flutter app receives the command

## 📊 WebSocket Protocol

### ESP32 → App (Commands)

```json
{
  "cmd": "play_pause",
  "seq": 123,
  "timestamp": 12345
}
```

**Commands:**
- `play_pause` - Toggle playback
- `next` - Next track
- `prev` - Previous track
- `volume_up` - Increase volume
- `volume_down` - Decrease volume
- `speed_cycle` - Change playback speed
- `repeat_cycle` - Change repeat mode
- `note` - Bookmark with timestamp
- `low_battery` - Battery warning (includes `voltage`)
- `status` - Connection status (includes `battery`, `rssi`)

### App → ESP32 (Responses)

```json
{
  "cmd": "ping"
}
```

```json
{
  "cmd": "get_status"
}
```

ESP32 responds with:
```json
{
  "cmd": "status",
  "battery": 3.5,
  "connected": true,
  "rssi": -45
}
```

## 🔋 Power Consumption

**WiFi uses more power than BLE:**
- **Active**: ~160-260mA (compared to BLE: ~20-40mA)
- **Idle**: ~15-20mA (compared to BLE: ~2-5mA)
- **Deep Sleep**: <10µA (same as BLE)

**Recommendations:**
1. Use USB power (recommended)
2. OR use larger battery (e.g., 18650 Li-ion)
3. Deep sleep after 5 minutes idle (configured)

## 🐛 Troubleshooting

### Can't Find WiFi Network (AP Mode)
- Check Serial Monitor - is it running?
- Try restarting ESP32
- Check LED: 2 slow blinks = AP started

### Can't Connect to WiFi (Station Mode)
- Verify SSID and password in code
- Check Serial Monitor for errors
- Try 2.4GHz WiFi (ESP32 doesn't support 5GHz)
- LED: 5 fast blinks = connection failed

### WebSocket Connection Failed
- Ping the ESP32: `ping 192.168.4.1`
- Check firewall settings
- Verify port 81 is not blocked
- Try telnet: `telnet 192.168.4.1 81`

### Buttons Not Responding
- Check Serial Monitor for button press logs
- LED should blink on each button press
- Verify WebSocket connection is active
- Check Flutter app is listening for messages

### High Power Consumption
- WiFi naturally uses more power than BLE
- Consider using USB power
- Idle timeout is set to 5 minutes
- Can adjust `IDLE_TIMEOUT_MS` in code

## 📝 Configuration Reference

**WiFi Settings:**
```cpp
#define WIFI_MODE_AP true          // AP mode vs Station mode
#define AP_SSID "AudioRemote_ESP32"
#define AP_PASSWORD "audio12345"
#define WS_PORT 81                 // WebSocket port
```

**Timing:**
```cpp
#define IDLE_TIMEOUT_MS 300000     // 5 minutes to deep sleep
#define WS_PING_INTERVAL 15000     // Keep-alive ping every 15s
#define WIFI_CONNECT_TIMEOUT 20000 // WiFi connection timeout
```

**GPIO Pins (same as BLE version):**
```cpp
BTN_PLAY_PAUSE  = 0
BTN_NEXT        = 2
BTN_PREV        = 4
BTN_VOL_UP      = 12
BTN_VOL_DOWN    = 13
BTN_SPEED       = 14
BTN_REPEAT      = 15
BTN_NOTE        = 27
LED_STATUS      = 21
```

## 🎯 Next Steps

1. ✅ Build and upload ESP32 firmware
2. ✅ Test WiFi connection
3. ⬜ Update Flutter app to use WebSocket
4. ⬜ Test button commands
5. ⬜ Deploy to device

## 📚 Resources

- [WebSockets Library](https://github.com/Links2004/arduinoWebSockets)
- [ArduinoJson Documentation](https://arduinojson.org/)
- [ESP32 WiFi API](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/network/esp_wifi.html)
- [Flutter WebSocket](https://pub.dev/packages/web_socket_channel)

## 🆘 Support

If you encounter issues:
1. Check Serial Monitor output (`#define DEBUG`)
2. Verify WiFi signal strength
3. Test with WebSocket client tool
4. Check GitHub issues

---

**Version 2.0.0** - WiFi Edition  
Migration from BLE completed successfully! 🎉
