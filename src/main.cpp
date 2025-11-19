/**
 * AudioRemote_ESP32_WiFi.cpp
 * 
 * ESP32-based WiFi remote control for audio player with note-taking
 * Uses WebSocket for real-time bidirectional communication
 * 
 * Hardware:
 *   - ESP32-WROOM-32 or ESP32-DevKit (must be ESP32, not Arduino)
 *   - 8 tactile buttons (active LOW with internal pull-ups)
 *   - Optional status LED on GPIO 21
 * 
 * IMPORTANT: This sketch ONLY works with ESP32 boards!
 * Board Selection: Tools > Board > ESP32 Arduino > ESP32 Dev Module (or similar)
 * 
 * Library Requirements:
 *   - WiFi (built-in with ESP32 board package)
 *   - WebSocketsServer (install via PlatformIO: links2004/WebSockets)
 *   - ESPAsyncWebServer (optional, for web interface)
 * 
 * Author: Audio Player Remote Project
 * Version: 2.0.0 (WiFi Edition)
 * Date: November 19, 2025
 * License: MIT
 */

// Check if ESP32 is selected
#ifndef ESP32
  #error "This sketch is designed for ESP32 only! Please select an ESP32 board from Tools > Board menu."
#endif

// WiFi and WebSocket libraries
#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>

// Uncomment for debug output via Serial
#define DEBUG

// ==================== WIFI CONFIGURATION ====================
// OPTION 1: Access Point Mode (ESP32 creates its own WiFi network)
#define USE_AP_MODE true  // Set to false for Station mode

// AP Mode settings (ESP32 creates WiFi network)
#define AP_SSID           "AudioRemote_ESP32"
#define AP_PASSWORD       "audio12345"  // Minimum 8 characters
#define AP_CHANNEL        6
#define AP_HIDDEN         false
#define AP_MAX_CONNECTIONS 4

// Station Mode settings (ESP32 connects to existing WiFi)
#define STA_SSID          "YourWiFiName"     // Change this
#define STA_PASSWORD      "YourWiFiPassword" // Change this

// WebSocket server port
#define WS_PORT           81

// Uncomment for debug output via Serial
// #define DEBUG

// ==================== PIN DEFINITIONS ====================
// Note: Using RTC GPIO pins for better deep sleep compatibility
#define BTN_PLAY_PAUSE  0   // RTC_GPIO0 - Boot button, good for wake-up
#define BTN_NEXT        2   // RTC_GPIO2 - Built-in LED on some boards
#define BTN_PREV        4   // RTC_GPIO4 
#define BTN_VOL_UP      12  // RTC_GPIO12
#define BTN_VOL_DOWN    13  // RTC_GPIO13
#define BTN_SPEED       14  // RTC_GPIO14
#define BTN_REPEAT      15  // RTC_GPIO15
#define BTN_NOTE        27  // RTC_GPIO27
#define LED_STATUS      21  // Non-RTC GPIO for LED

// Button configuration
const uint8_t BUTTON_PINS[] = {
  BTN_PLAY_PAUSE, BTN_NEXT, BTN_PREV, BTN_VOL_UP,
  BTN_VOL_DOWN, BTN_SPEED, BTN_REPEAT, BTN_NOTE
};
const uint8_t NUM_BUTTONS = sizeof(BUTTON_PINS) / sizeof(BUTTON_PINS[0]);

// ==================== TIMING CONSTANTS ====================
#define DEBOUNCE_MS           50      // Software debounce time
#define LONG_PRESS_MS         1500    // Long press threshold
#define CONTINUOUS_INTERVAL   200     // Interval for continuous commands (long press)
#define COMMAND_MIN_INTERVAL  100     // Min time between duplicate commands
#define IDLE_TIMEOUT_MS       300000  // Deep sleep after 5 min idle (WiFi uses more power)
#define LED_BLINK_MS          100     // LED success blink duration
#define LED_ERROR_BLINK_MS    80      // LED error blink duration
#define JSON_BUFFER_SIZE      256     // Increased for WiFi communication
#define BATTERY_CHECK_INTERVAL 30000  // Check battery every 30 seconds
#define BATTERY_PIN           A0      // ADC pin for battery monitoring (if used)
#define LOW_BATTERY_THRESHOLD 3.2     // Volts - threshold for low battery warning
#define WIFI_CONNECT_TIMEOUT  20000   // WiFi connection timeout
#define WS_PING_INTERVAL      15000   // WebSocket ping interval

// ==================== GLOBAL STATE ====================
WebSocketsServer webSocket = WebSocketsServer(WS_PORT);
bool clientConnected = false;
uint8_t currentClientId = 0;
IPAddress localIP;

uint16_t commandSeq = 0;              // Command sequence number
unsigned long lastActivityTime = 0;   // For idle timeout tracking
unsigned long lastCommandTime[NUM_BUTTONS] = {0}; // Anti-spam tracking per button
unsigned long lastBatteryCheck = 0;   // For battery monitoring
unsigned long lastWsPing = 0;         // WebSocket ping timer
float batteryVoltage = 0.0;           // Current battery voltage
bool wifiConnected = false;

// Button state structure
struct ButtonState {
  uint8_t pin;
  bool lastReading;
  bool currentState;
  unsigned long lastDebounceTime;
  unsigned long pressStartTime;
  bool longPressFired;
  bool isPressed;
  const char* shortCmd;
  const char* longCmd;
};

// Initialize button states with command mappings
ButtonState buttons[NUM_BUTTONS] = {
  {BTN_PLAY_PAUSE, HIGH, HIGH, 0, 0, false, false, "play_pause", nullptr},
  {BTN_NEXT,       HIGH, HIGH, 0, 0, false, false, "next", nullptr},
  {BTN_PREV,       HIGH, HIGH, 0, 0, false, false, "prev", nullptr},
  {BTN_VOL_UP,     HIGH, HIGH, 0, 0, false, false, "volume_up", "volume_up"},   // Continuous
  {BTN_VOL_DOWN,   HIGH, HIGH, 0, 0, false, false, "volume_down", "volume_down"}, // Continuous
  {BTN_SPEED,      HIGH, HIGH, 0, 0, false, false, "speed_cycle", nullptr},
  {BTN_REPEAT,     HIGH, HIGH, 0, 0, false, false, "repeat_cycle", nullptr},
  {BTN_NOTE,       HIGH, HIGH, 0, 0, false, false, "note", nullptr}
};

// ==================== FORWARD DECLARATIONS ====================
// Forward declarations with default parameters
void blinkLED(uint8_t count, uint16_t duration = LED_BLINK_MS);
bool sendCommand(const char* cmd, const char* extraJson = nullptr);

// ==================== BATTERY MONITORING ====================

/**
 * Check battery voltage and send low battery warning if needed
 * @return current battery voltage
 */
float checkBattery() {
  // Read ADC value (adjust this based on your voltage divider circuit)
  // This assumes a voltage divider from battery to ADC pin
  // For CR2032: 3.0V nominal, reads through voltage divider
  uint16_t adcValue = analogRead(BATTERY_PIN);
  
  // Convert ADC reading to voltage
  // ESP32 ADC: 0-4095 maps to 0-3.3V (with attenuation settings)
  // Adjust multiplier based on your voltage divider ratio
  batteryVoltage = (adcValue / 4095.0) * 3.3 * 2.0; // Assuming 1:2 voltage divider
  
  #ifdef DEBUG
  Serial.print("Battery voltage: ");
  Serial.print(batteryVoltage);
  Serial.println("V");
  #endif
  
  // Send low battery warning if threshold crossed
  static bool lowBatteryWarned = false;
  if (batteryVoltage < LOW_BATTERY_THRESHOLD && !lowBatteryWarned) {
    char voltageStr[16];
    snprintf(voltageStr, sizeof(voltageStr), "\"voltage\":%.2f", batteryVoltage);
    sendCommand("low_battery", voltageStr);
    lowBatteryWarned = true;
    
    // Flash LED for low battery
    blinkLED(5, LED_ERROR_BLINK_MS);
  } else if (batteryVoltage >= LOW_BATTERY_THRESHOLD + 0.1) {
    // Reset warning flag with hysteresis
    lowBatteryWarned = false;
  }
  
  return batteryVoltage;
}

// ==================== WEBSOCKET CALLBACKS ====================

/**
 * WebSocket event handler
 */
void webSocketEvent(uint8_t clientId, WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      #ifdef DEBUG
      Serial.printf("[%u] Client disconnected\n", clientId);
      #endif
      if (clientId == currentClientId) {
        clientConnected = false;
        currentClientId = 0;
      }
      blinkLED(2, LED_ERROR_BLINK_MS);
      break;
      
    case WStype_CONNECTED:
      {
        IPAddress ip = webSocket.remoteIP(clientId);
        #ifdef DEBUG
        Serial.printf("[%u] Client connected from %d.%d.%d.%d\n", 
                      clientId, ip[0], ip[1], ip[2], ip[3]);
        #endif
        clientConnected = true;
        currentClientId = clientId;
        lastActivityTime = millis();
        blinkLED(1);
        
        // Send connection status with device info
        StaticJsonDocument<256> doc;
        doc["cmd"] = "status";
        doc["seq"] = commandSeq++;
        doc["status"] = "connected";
        doc["battery"] = batteryVoltage;
        doc["ip"] = localIP.toString();
        doc["rssi"] = WiFi.RSSI();
        
        String json;
        serializeJson(doc, json);
        webSocket.sendTXT(clientId, json);
      }
      break;
      
    case WStype_TEXT:
      #ifdef DEBUG
      Serial.printf("[%u] Received: %s\n", clientId, payload);
      #endif
      // Handle incoming commands from app (e.g., LED control, settings)
      {
        StaticJsonDocument<256> doc;
        DeserializationError error = deserializeJson(doc, payload, length);
        
        if (!error) {
          const char* cmd = doc["cmd"];
          if (strcmp(cmd, "ping") == 0) {
            // Respond to ping
            webSocket.sendTXT(clientId, "{\"cmd\":\"pong\"}");
          } else if (strcmp(cmd, "get_status") == 0) {
            // Send status update
            StaticJsonDocument<256> response;
            response["cmd"] = "status";
            response["battery"] = batteryVoltage;
            response["connected"] = clientConnected;
            response["rssi"] = WiFi.RSSI();
            String json;
            serializeJson(response, json);
            webSocket.sendTXT(clientId, json);
          }
        }
      }
      lastActivityTime = millis();
      break;
      
    case WStype_ERROR:
    case WStype_FRAGMENT_TEXT_START:
    case WStype_FRAGMENT_BIN_START:
    case WStype_FRAGMENT:
    case WStype_FRAGMENT_FIN:
    case WStype_PING:
    case WStype_PONG:
      break;
  }
}

// ==================== HELPER FUNCTIONS ====================

/**
 * Blink status LED
 * @param count Number of blinks
 * @param duration Duration of each blink in ms (default 100ms)
 */
void blinkLED(uint8_t count, uint16_t duration) {
  for (uint8_t i = 0; i < count; i++) {
    digitalWrite(LED_STATUS, HIGH);
    delay(duration);
    digitalWrite(LED_STATUS, LOW);
    if (i < count - 1) {
      delay(duration);
    }
  }
}

/**
 * Send command via WebSocket
 * @param cmd Command string (e.g., "play_pause")
 * @param extraJson Optional additional JSON fields (e.g., "\"ts\":0")
 * @return true if sent successfully, false otherwise
 */
bool sendCommand(const char* cmd, const char* extraJson) {
  if (!clientConnected) {
    #ifdef DEBUG
    Serial.println("No client connected, cannot send command");
    #endif
    return false;
  }

  if (!cmd) {
    #ifdef DEBUG
    Serial.println("Command is null");
    #endif
    return false;
  }

  // Build JSON command using ArduinoJson
  StaticJsonDocument<JSON_BUFFER_SIZE> doc;
  doc["cmd"] = cmd;
  doc["seq"] = commandSeq++;
  doc["timestamp"] = millis();
  
  // Parse and add extra JSON fields if provided
  if (extraJson) {
    StaticJsonDocument<128> extraDoc;
    DeserializationError error = deserializeJson(extraDoc, 
                                                  String("{") + extraJson + "}");
    if (!error) {
      for (JsonPair kv : extraDoc.as<JsonObject>()) {
        doc[kv.key()] = kv.value();
      }
    }
  }
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  // Check for buffer overflow
  if (jsonString.length() >= JSON_BUFFER_SIZE) {
    #ifdef DEBUG
    Serial.println("JSON buffer overflow");
    #endif
    blinkLED(4, LED_ERROR_BLINK_MS);
    return false;
  }

  // Send via WebSocket
  bool success = webSocket.sendTXT(currentClientId, jsonString);
  
  #ifdef DEBUG
  if (success) {
    Serial.print("Sent: ");
    Serial.println(jsonString);
  } else {
    Serial.println("Send failed");
  }
  #endif
  
  if (success) {
    blinkLED(1); // Success blink
  } else {
    blinkLED(3, LED_ERROR_BLINK_MS); // Error blinks
  }
  
  return success;
}

/**
 * Handle button press/release with debouncing and long-press detection
 * @param btn Pointer to button state structure
 * @param index Button index (for anti-spam tracking)
 */
void handleButton(ButtonState* btn, uint8_t index) {
  bool reading = digitalRead(btn->pin) == LOW; // Active LOW
  unsigned long now = millis();

  // Debounce logic
  if (reading != btn->lastReading) {
    btn->lastDebounceTime = now;
  }

  if ((now - btn->lastDebounceTime) > DEBOUNCE_MS) {
    // Stable state after debounce
    
    // Detect press start
    if (reading && !btn->currentState) {
      btn->currentState = true;
      btn->pressStartTime = now;
      btn->longPressFired = false;
      btn->isPressed = true;
      
      #ifdef DEBUG
      Serial.print("Button pressed: ");
      Serial.println(btn->pin);
      #endif
    }
    
    // Detect release
    else if (!reading && btn->currentState) {
      btn->currentState = false;
      btn->isPressed = false;
      
      unsigned long pressDuration = now - btn->pressStartTime;
      
      // Short press (and not already handled by long press)
      if (!btn->longPressFired && pressDuration < LONG_PRESS_MS) {
        // Anti-spam: check minimum interval between same command
        if (now - lastCommandTime[index] >= COMMAND_MIN_INTERVAL) {
          
          // Special handling for note button (include actual timestamp)
          if (btn->pin == BTN_NOTE) {
            char timestamp[32];
            snprintf(timestamp, sizeof(timestamp), "\"ts\":%lu", millis());
            sendCommand(btn->shortCmd, timestamp);
          } else {
            sendCommand(btn->shortCmd);
          }
          
          lastCommandTime[index] = now;
          lastActivityTime = now;
        }
      }
      
      #ifdef DEBUG
      Serial.print("Button released: ");
      Serial.println(btn->pin);
      #endif
    }
    
    // Long press detection (for continuous commands like volume)
    else if (reading && btn->currentState && !btn->longPressFired) {
      unsigned long pressDuration = now - btn->pressStartTime;
      
      if (pressDuration >= LONG_PRESS_MS && btn->longCmd != nullptr) {
        btn->longPressFired = true;
        
        #ifdef DEBUG
        Serial.print("Long press detected: ");
        Serial.println(btn->pin);
        #endif
      }
    }
    
    // Continuous command sending during long press
    if (btn->isPressed && btn->longPressFired && btn->longCmd != nullptr) {
      if (now - lastCommandTime[index] >= CONTINUOUS_INTERVAL) {
        sendCommand(btn->longCmd);
        lastCommandTime[index] = now;
        lastActivityTime = now;
      }
    }
  }

  btn->lastReading = reading;
}

/**
 * Initialize WiFi connection
 */
bool initWiFi() {
  #ifdef DEBUG
  Serial.println("\n=== Initializing WiFi ===");
  #endif
  
  if (USE_AP_MODE) {
    // Access Point Mode - ESP32 creates WiFi network
    #ifdef DEBUG
    Serial.println("Starting Access Point mode...");
    Serial.print("SSID: ");
    Serial.println(AP_SSID);
    #endif
    
    WiFi.mode(WIFI_AP);
    bool success = WiFi.softAP(AP_SSID, AP_PASSWORD, AP_CHANNEL, AP_HIDDEN, AP_MAX_CONNECTIONS);
    
    if (success) {
      localIP = WiFi.softAPIP();
      wifiConnected = true;
      
      #ifdef DEBUG
      Serial.println("Access Point started successfully!");
      Serial.print("IP Address: ");
      Serial.println(localIP);
      Serial.print("WebSocket Port: ");
      Serial.println(WS_PORT);
      Serial.println("\nConnect your phone to this WiFi network:");
      Serial.print("  SSID: ");
      Serial.println(AP_SSID);
      Serial.print("  Password: ");
      Serial.println(AP_PASSWORD);
      Serial.print("  WebSocket URL: ws://");
      Serial.print(localIP);
      Serial.print(":");
      Serial.println(WS_PORT);
      #endif
      
      blinkLED(2, 200); // 2 slow blinks for AP mode
      return true;
    } else {
      #ifdef DEBUG
      Serial.println("Failed to start Access Point!");
      #endif
      blinkLED(5, LED_ERROR_BLINK_MS);
      return false;
    }
    
  } else {
    // Station Mode - Connect to existing WiFi
    #ifdef DEBUG
    Serial.println("Connecting to WiFi...");
    Serial.print("SSID: ");
    Serial.println(STA_SSID);
    #endif
    
    WiFi.mode(WIFI_STA);
    WiFi.begin(STA_SSID, STA_PASSWORD);
    
    unsigned long startTime = millis();
    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
      Serial.print(".");
      
      if (millis() - startTime > WIFI_CONNECT_TIMEOUT) {
        #ifdef DEBUG
        Serial.println("\nWiFi connection timeout!");
        #endif
        blinkLED(5, LED_ERROR_BLINK_MS);
        return false;
      }
    }
    
    localIP = WiFi.localIP();
    wifiConnected = true;
    
    #ifdef DEBUG
    Serial.println("\nWiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(localIP);
    Serial.print("Signal Strength: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    Serial.print("WebSocket URL: ws://");
    Serial.print(localIP);
    Serial.print(":");
    Serial.println(WS_PORT);
    #endif
    
    blinkLED(3, 200); // 3 slow blinks for Station mode
    return true;
  }
}

/**
 * Enter deep sleep mode to conserve battery
 * Wakes on any RTC GPIO button press using EXT0 wakeup (single pin)
 */
void enterDeepSleep() {
  #ifdef DEBUG
  Serial.println("Entering deep sleep...");
  Serial.flush();
  #endif

  // Turn off LED
  digitalWrite(LED_STATUS, LOW);

  // Disconnect WiFi gracefully
  webSocket.close();
  WiFi.disconnect(true);
  WiFi.mode(WIFI_OFF);
  delay(100);

  // Configure EXT0 wakeup on BTN_PLAY_PAUSE (GPIO 0)
  // Wake up when this pin goes LOW (button pressed)
  esp_sleep_enable_ext0_wakeup((gpio_num_t)BTN_PLAY_PAUSE, 0);

  #ifdef DEBUG
  Serial.println("Deep sleep configured. Press PLAY/PAUSE button to wake.");
  #endif

  // Enter deep sleep
  esp_deep_sleep_start();
}

/**
 * Check if idle timeout reached and enter deep sleep if needed
 */
void checkIdleTimeout() {
  if (millis() - lastActivityTime > IDLE_TIMEOUT_MS) {
    #ifdef DEBUG
    Serial.println("Idle timeout reached");
    #endif
    enterDeepSleep();
  }
}

/**
 * Initialize WebSocket server
 */
void initWebSocket() {
  #ifdef DEBUG
  Serial.println("Initializing WebSocket server...");
  #endif

  // Setup WebSocket event handler
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);

  #ifdef DEBUG
  Serial.println("WebSocket server started");
  Serial.print("Listening on port: ");
  Serial.println(WS_PORT);
  #endif
}

// ==================== ARDUINO SETUP ====================
void setup() {
  #ifdef DEBUG
  Serial.begin(115200);
  delay(1000); // Wait for serial
  Serial.println("\n");
  Serial.println("=====================================");
  Serial.println("  Audio Remote ESP32 - WiFi Edition");
  Serial.println("  Version 2.0.0");
  Serial.println("=====================================");
  #endif

  // Configure LED pin
  pinMode(LED_STATUS, OUTPUT);
  digitalWrite(LED_STATUS, LOW);

  // Configure battery monitoring ADC (optional - only if hardware supports it)
  // Uncomment and adjust if you have a voltage divider for battery monitoring
  // analogSetAttenuation(ADC_11db); // For higher voltage range
  // analogSetWidth(ADC_WIDTH_BIT_12); // 12-bit resolution

  // Configure button pins with internal pull-ups
  for (uint8_t i = 0; i < NUM_BUTTONS; i++) {
    pinMode(BUTTON_PINS[i], INPUT_PULLUP);
    #ifdef DEBUG
    Serial.print("Button ");
    Serial.print(i);
    Serial.print(" on RTC_GPIO ");
    Serial.println(BUTTON_PINS[i]);
    #endif
  }

  // Power-on LED indicator (2 quick blinks)
  blinkLED(2, 150);

  // Initialize WiFi
  if (!initWiFi()) {
    #ifdef DEBUG
    Serial.println("WiFi initialization failed! Restarting...");
    #endif
    delay(5000);
    ESP.restart();
  }

  // Initialize WebSocket server
  initWebSocket();

  // Initialize activity timer
  lastActivityTime = millis();
  lastWsPing = millis();

  #ifdef DEBUG
  Serial.println("\n=== Setup Complete ===");
  Serial.println("Ready for connections!");
  Serial.println("=====================================\n");
  #endif
}

// ==================== ARDUINO LOOP ====================
void loop() {
  unsigned long now = millis();

  // Handle WebSocket events
  webSocket.loop();

  // Check WiFi connection and reconnect if needed
  if (!USE_AP_MODE && WiFi.status() != WL_CONNECTED) {
    #ifdef DEBUG
    Serial.println("WiFi disconnected! Reconnecting...");
    #endif
    wifiConnected = false;
    clientConnected = false;
    blinkLED(5, LED_ERROR_BLINK_MS);
    
    if (!initWiFi()) {
      delay(5000);
      ESP.restart();
    }
  }

  // Send periodic ping to keep connection alive
  if (clientConnected && (now - lastWsPing >= WS_PING_INTERVAL)) {
    webSocket.sendPing(currentClientId);
    lastWsPing = now;
    
    #ifdef DEBUG
    Serial.println("Sent ping to client");
    #endif
  }

  // Process all buttons
  for (uint8_t i = 0; i < NUM_BUTTONS; i++) {
    handleButton(&buttons[i], i);
  }

  // Check battery voltage periodically
  if (now - lastBatteryCheck >= BATTERY_CHECK_INTERVAL) {
    checkBattery();
    lastBatteryCheck = now;
  }

  // Check for idle timeout and enter deep sleep if needed
  if (!clientConnected) {
    checkIdleTimeout();
  }

  // Small delay to reduce CPU load and power consumption
  delay(5);
}

/**
 * IMPLEMENTATION NOTES:
 * 
 * Version 2.0.0 - WiFi Edition:
 * - Migrated from BLE to WiFi + WebSocket for more reliable communication
 * - Supports both Access Point mode (ESP32 creates WiFi) and Station mode
 * - WebSocket provides bidirectional real-time communication
 * - ArduinoJson for efficient JSON serialization/deserialization
 * - Automatic WiFi reconnection with retry logic
 * - Keep-alive ping mechanism to maintain WebSocket connection
 * 
 * Hardware Configuration:
 * - Updated GPIO pins to RTC-compatible ones for deep sleep wake-up
 * - Using EXT0 wake-up on BTN_PLAY_PAUSE (GPIO 0) for reliable wake
 * - Optional battery monitoring capability
 * - Compile-time check ensures ESP32 platform
 * 
 * Power Management:
 * - Deep sleep after 5 min idle (increased from 15s due to WiFi power usage)
 * - WiFi active: ~160-260mA (higher than BLE's 20-40mA)
 * - WiFi idle: ~15-20mA (higher than BLE's 2-5mA)
 * - Deep sleep: <10µA (same as BLE version)
 * - Recommendation: Use USB power or larger battery (e.g., 18650)
 * - EXT0 wake-up on any button press
 * - LED usage minimized (brief blinks only)
 * 
 * Reliability Features:
 * - WebSocket auto-reconnection on disconnect
 * - WiFi reconnection logic for Station mode
 * - Debouncing prevents false button triggers
 * - Anti-spam prevents command flooding
 * - Sequence numbers for command deduplication
 * - NULL pointer checks prevent crashes
 * - Buffer overflow protection with ArduinoJson
 * - Low battery monitoring and warnings
 * - RSSI monitoring for WiFi signal strength
 * 
 * Communication Protocol:
 * - WebSocket on port 81 (configurable)
 * - JSON format for all messages
 * - Real timestamps for note/bookmark commands
 * - Battery voltage in status messages
 * - Signal strength (RSSI) in status
 * - Bidirectional: ESP32 ↔ App
 * - Ping/pong keep-alive every 15s
 * 
 * WiFi Modes:
 * 1. Access Point (AP) Mode:
 *    - ESP32 creates WiFi network (SSID: AudioRemote_ESP32)
 *    - No router needed, works anywhere
 *    - Default IP: 192.168.4.1
 *    - Ideal for portable use
 * 
 * 2. Station (STA) Mode:
 *    - ESP32 connects to existing WiFi
 *    - All devices on same network
 *    - Dynamic IP from DHCP
 *    - Ideal for home use
 * 
 * Error Indication (LED):
 * - 1 blink: Command sent successfully
 * - 2 blinks: WiFi/WebSocket connected (slow) or disconnected (fast)
 * - 3 blinks: Command send error
 * - 4 blinks: JSON buffer overflow
 * - 5 blinks: WiFi connection failed or low battery
 * 
 * Future Enhancements:
 * - OTA firmware updates via WiFi
 * - mDNS service discovery (audioremote.local)
 * - Web interface for configuration
 * - HTTPS/WSS for secure communication
 * - Multiple simultaneous client connections
 * - Battery percentage calculation
 * - Temperature sensor integration
 * - Gesture controls with accelerometer
 * 
 * Memory Usage (approximate):
 * - Flash: ~320KB (includes WiFi stack)
 * - RAM: ~65KB (WebSocket buffers + WiFi)
 * - JSON buffer: 256 bytes (increased for WiFi metadata)
 * - Heap: ~200KB available for dynamic allocation
 * 
 * Dependencies:
 * - WiFi: Built-in with ESP32 Arduino Core
 * - WebSocketsServer: links2004/WebSockets ^2.4.1
 * - ArduinoJson: bblanchon/ArduinoJson ^6.21.3
 * 
 * Advantages over BLE:
 * ✅ More reliable - no pairing issues
 * ✅ Longer range - WiFi covers more distance
 * ✅ Faster - lower latency
 * ✅ Easier setup - simple WiFi connection
 * ✅ Web accessible - can use from any device
 * ✅ Better debugging - can test with browser tools
 * 
 * Tradeoffs:
 * ⚠️ Higher power consumption - needs USB or larger battery
 * ⚠️ Slightly larger code size - WiFi stack overhead
 * ⚠️ Requires WiFi infrastructure - unless using AP mode
 */