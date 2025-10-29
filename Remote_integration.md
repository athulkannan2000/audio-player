# Audio Player Remote Integration (ESP32 Hardware Controller)

## Integration Overview

### Why ESP32 + BLE?

**Technical rationale:**
- **Cost-effective**: ESP32 modules cost ~$2–4 in bulk; complete remote BOM under $8/unit including enclosure.
- **Power efficiency**: BLE 4.2/5.0 with deep sleep draws <10μA idle; enables 6+ months on CR2032 coin cell.
- **Mature ecosystem**: Arduino/PlatformIO support, rich BLE libraries (NimBLE-Arduino, ESP-IDF), extensive community resources.
- **Integrated connectivity**: Built-in BLE and Wi-Fi (we prefer BLE for power but Wi-Fi available as fallback).
- **Processing headroom**: 240MHz dual-core allows local debouncing, buffering, and potential future features (haptics, small OLED display).

**User benefit:**
- **Accessibility**: Enables hands-free operation for users with motor impairments or visual impairments (tactile button layout).
- **Driving safety**: Legal and safe podcast/audiobook control without screen interaction while driving.
- **Eyes-free learning**: Students can take timestamped notes during lectures or study sessions without breaking flow or looking at screen.
- **Universal input**: Works across iOS/Android/Web (via Web Bluetooth) with consistent button mapping.

**Philosophy:**
The remote is an optional enhancement—a physical manifestation of the state contract defined in `Audio_player.md`. It sends commands that the app interprets as standard user actions, preserving the single-source-of-truth state model. The app remains fully functional via touchscreen; the remote simply provides an alternative, ergonomic input modality.

---

## Remote Hardware Specification

### Core Components

**ESP32 Module**
- Recommended: ESP32-WROOM-32 or ESP32-C3 (RISC-V, lower cost)
- Flash: 4MB minimum
- BLE: Bluetooth 4.2 or 5.0 (5.0 preferred for range and power)

**Buttons (8 tactile switches)**

| Button Label | Primary Function | Long-Press (Optional) |
|-------------|------------------|----------------------|
| ▶️⏸ | Play / Pause | — |
| ⏭ | Next track / +15s seek | +30s seek |
| ⏮ | Previous track / –15s seek | –30s seek |
| VOL+ | Volume up (+10%) | Max volume |
| VOL– | Volume down (–10%) | Mute toggle |
| 🔄 SPEED | Cycle speed: 1.0→1.5→2.0→0.75→1.0 | Reset to 1.0x |
| 🔁 REPEAT | Cycle: off→one→all→off | — |
| 📝 NOTE | Pause + trigger note input | Voice note (future) |

**Power & Status**
- Battery: CR2032 coin cell (220mAh) or 2× AAA (1000mAh) for extended life
- Voltage regulator: 3.3V LDO (if using AAA batteries)
- Status LED: Single RGB LED (optional)
  - Blue blink: BLE advertising
  - Green solid: Connected
  - Red blink: Low battery (<15%)
  - Off: Deep sleep

**Additional Components**
- Debounce capacitors: 100nF ceramic per button
- Pull-up resistors: 10kΩ for button inputs (or use internal ESP32 pull-ups)
- On/Off slide switch (optional power isolation)

**Enclosure**
- 3D-printable STL files (recommended design: ~60×40×15mm pocket-sized)
- Reference: [Thingiverse ESP32 Button Remote](https://www.thingiverse.com/thing:4567890) (adapt button layout)
- Material: PLA or PETG, 0.2mm layer height, 20% infill
- Tactile feedback: raised dots on ▶️⏸ and 📝 for blind operation

**BOM Cost Estimate (at scale, 100+ units)**
- ESP32-WROOM-32: $2.50
- 8× tactile switches: $0.80
- CR2032 + holder: $0.60
- PCB (custom, small run): $1.50
- RGB LED + resistors: $0.20
- Enclosure (3D print): $1.00 (filament + time)
- Misc (wire, solder): $0.40
- **Total: ~$7.00/unit**

---

## Firmware Design (ESP32 Side)

### Architecture Overview

**Modules:**
1. **Button Manager**: Debouncing, long-press detection, event generation
2. **BLE Server**: GATT service, characteristic notify/write handlers
3. **Power Manager**: Deep sleep scheduling, battery monitoring
4. **Command Encoder**: Translate button events to protocol messages

### Button Debouncing Logic

```cpp
// Debounce parameters
#define DEBOUNCE_MS 50
#define LONG_PRESS_MS 800

struct Button {
  uint8_t pin;
  bool lastState;
  unsigned long lastDebounceTime;
  unsigned long pressStartTime;
  bool longPressFired;
};

void handleButton(Button* btn) {
  bool reading = digitalRead(btn->pin) == LOW; // Active low
  
  if (reading != btn->lastState) {
    btn->lastDebounceTime = millis();
  }
  
  if ((millis() - btn->lastDebounceTime) > DEBOUNCE_MS) {
    // Stable state
    if (reading && !btn->lastState) {
      // Press started
      btn->pressStartTime = millis();
      btn->longPressFired = false;
    }
    else if (!reading && btn->lastState) {
      // Release
      unsigned long pressDuration = millis() - btn->pressStartTime;
      if (!btn->longPressFired) {
        if (pressDuration < LONG_PRESS_MS) {
          sendCommand(btn->pin, "short");
        }
      }
    }
    else if (reading && (millis() - btn->pressStartTime) > LONG_PRESS_MS && !btn->longPressFired) {
      // Long press threshold reached
      btn->longPressFired = true;
      sendCommand(btn->pin, "long");
    }
  }
  
  btn->lastState = reading;
}
```

### BLE GATT Service Definition

**Service UUID**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b` (custom, registered)

**Characteristics:**

1. **Command TX (ESP32 → App)**
   - UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
   - Properties: Notify
   - Payload: JSON string (max 128 bytes)
   
2. **Status RX (App → ESP32)**
   - UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a9`
   - Properties: Write
   - Payload: JSON string (state confirmation or battery query)

3. **Battery Level (standard)**
   - UUID: `0x2A19` (Battery Service standard)
   - Properties: Read, Notify
   - Payload: uint8 (0–100%)

### Command Protocol Format

**JSON-based (human-readable, extensible):**

```json
{
  "cmd": "play_pause",
  "seq": 42,
  "timestamp": 1698512345
}
```

**Field definitions:**
- `cmd`: Command string (see table below)
- `seq`: Sequence number (increments per command, wraps at 65535) for deduplication
- `timestamp`: Unix timestamp (seconds) from ESP32 RTC for latency measurement (optional)

**Command table:**

| `cmd` value | Action | Parameters |
|------------|--------|-----------|
| `play_pause` | Toggle play/pause | — |
| `next` | Next track or +15s | — |
| `prev` | Previous track or –15s | — |
| `volume_up` | Increase volume 10% | — |
| `volume_down` | Decrease volume 10% | — |
| `volume_max` | Set volume to 1.0 | (long press) |
| `volume_mute` | Toggle mute | (long press) |
| `speed_cycle` | Cycle speed preset | — |
| `speed_reset` | Set speed to 1.0x | (long press) |
| `repeat_cycle` | Cycle repeat mode | — |
| `note` | Trigger note input | `{"cmd":"note","position_ms":125000}` |
| `ping` | Keep-alive / test | — |

**Binary alternative (for ultra-low power):**
```
[0x01 CMD_BYTE] [0x02 SEQ_HIGH] [0x03 SEQ_LOW] [0x04 CHECKSUM]
```
- 4 bytes per command
- CMD_BYTE enum: 0x01=play_pause, 0x02=next, 0x03=prev, etc.
- Trade-off: less human-readable but saves ~100 bytes/command (minimal BLE packet advantage)

**Recommendation**: Use JSON for Phase 1 (easier debugging); optimize to binary if power profiling shows significant BLE TX overhead.

### Power-Saving Strategy

**Deep sleep logic:**
```cpp
void enterDeepSleep() {
  esp_sleep_enable_ext0_wakeup(GPIO_NUM_X, 0); // Wake on any button (OR gate)
  esp_deep_sleep_start();
}

void loop() {
  handleAllButtons();
  
  if (millis() - lastButtonPress > IDLE_TIMEOUT_MS) {
    if (bleConnected) {
      // Send disconnect notification
      bleDisconnect();
    }
    enterDeepSleep();
  }
}
```

**Power budget:**
- Active (BLE connected): ~40mA @ 3.3V (short bursts)
- Idle (advertising): ~5mA
- Deep sleep: <10μA
- Button press wakeup: <50ms to active

**Battery life estimate (CR2032, 220mAh):**
- Assume 20 button presses/day × 2s active = 40s active/day
- Active power: 40mA × (40/86400)h = 0.018mAh/day
- Advertising 1h/day: 5mA × (1/24)h = 0.21mAh/day
- Sleep 22.3h/day: 0.01mA × 22.3h = 0.22mAh/day
- **Total: ~0.45mAh/day → 220/0.45 = 489 days (~16 months)**

Realistic with connection overhead: **6–10 months** on CR2032.

### Sample Firmware Skeleton (Arduino/PlatformIO)

```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

BLECharacteristic* pCommandChar;
uint16_t seqNum = 0;

void setup() {
  // Init buttons with internal pull-ups
  for (int i = 0; i < 8; i++) {
    pinMode(buttonPins[i], INPUT_PULLUP);
  }
  
  // Init BLE
  BLEDevice::init("AudioRemote");
  BLEServer* pServer = BLEDevice::createServer();
  BLEService* pService = pServer->createService(SERVICE_UUID);
  
  pCommandChar = pService->createCharacteristic(
    COMMAND_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pCommandChar->addDescriptor(new BLE2902());
  
  pService->start();
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();
}

void sendCommand(const char* cmd) {
  char json[128];
  snprintf(json, sizeof(json), "{\"cmd\":\"%s\",\"seq\":%d}", cmd, seqNum++);
  pCommandChar->setValue(json);
  pCommandChar->notify();
}

void loop() {
  for (int i = 0; i < 8; i++) {
    handleButton(&buttons[i]);
  }
  delay(10); // Simple polling; interrupt-driven alternative exists
}
```

---

## Mobile App Modifications

### New Modules & UI Components

**1. BLE Manager Module**
- Responsibilities:
  - Scan for ESP32 remote (filter by service UUID)
  - Maintain connection state (connected, scanning, paired)
  - Subscribe to command characteristic
  - Parse incoming JSON commands
  - Dispatch commands to existing state actions

**2. Pairing UI (one-time setup)**
- Screen flow:
  1. Settings → "Pair Remote"
  2. Scan for nearby devices (show signal strength)
  3. User selects "AudioRemote-XXXX"
  4. Optional: PIN confirmation (display 6-digit PIN on both devices)
  5. Save pairing info (device UUID + auth token) to secure storage

**3. Background BLE Listener**
- Platform-specific requirements:
  - **iOS**: Use Core Bluetooth background mode; declare `bluetooth-central` in Info.plist. Subscribe to characteristic notifications; iOS may throttle when app is suspended (expect 200–500ms latency).
  - **Android**: Foreground service with notification (required for Android 8+). Handle `onCharacteristicChanged` in service, not activity.
  - **Web**: Web Bluetooth API (Chrome/Edge); requires user gesture to initiate pairing; background requires PWA with service worker (experimental).

**4. Command Mapping Layer**

```dart
// Flutter example (Riverpod)
void handleRemoteCommand(String jsonCmd) {
  final cmd = jsonDecode(jsonCmd);
  final cmdType = cmd['cmd'];
  final seq = cmd['seq'];
  
  // Deduplication check
  if (seq <= lastSeq) return;
  lastSeq = seq;
  
  // Dispatch to state actions
  switch (cmdType) {
    case 'play_pause':
      ref.read(playbackProvider.notifier).togglePlay();
      break;
    case 'next':
      ref.read(playbackProvider.notifier).seek(
        ref.read(playbackProvider).position_ms + 15000
      );
      break;
    case 'volume_up':
      final vol = ref.read(playbackProvider).volume;
      ref.read(playbackProvider.notifier).setVolume(
        (vol + 0.1).clamp(0.0, 1.0)
      );
      break;
    case 'speed_cycle':
      final speeds = [1.0, 1.5, 2.0, 0.75];
      final current = ref.read(playbackProvider).speed;
      final idx = speeds.indexOf(current);
      final next = speeds[(idx + 1) % speeds.length];
      ref.read(playbackProvider.notifier).setSpeed(next);
      break;
    case 'note':
      ref.read(playbackProvider.notifier).pause();
      final posMs = ref.read(playbackProvider).position_ms;
      // Open quick-input modal with pre-filled timestamp
      showNoteDialog(context, posMs);
      break;
    // ... other cases
  }
  
  // Optional: send ACK back to remote (LED feedback)
  bleManager.sendStatus({"ack": seq, "state": "ok"});
}
```

**5. Quick-Input Note Modal (triggered by remote)**
- Auto-pause playback on `note` command received
- Pre-fill timestamp field with human-readable time (e.g., "2:05")
- Show voice-to-text option (platform speech recognition API)
- Save note on confirm, resume playback (or keep paused, user choice)

---

## Security & Reliability

### Pairing & Authentication

**Approach 1: BLE Passkey (recommended for simplicity)**
- ESP32 displays a 6-digit PIN on serial or optional OLED (or hardcoded for prototyping: `123456`)
- Mobile app prompts user to enter PIN during pairing
- BLE stack handles secure pairing (Just Works or Passkey Entry)

**Approach 2: QR Code Pairing (UX-friendly)**
- Remote prints QR code on enclosure or displays on small e-paper screen
- QR contains: `{device_uuid, shared_secret}`
- App scans QR → auto-pairs with encrypted bond

**Approach 3: Physical Confirmation**
- User presses button sequence on remote (e.g., ▶️ + 📝 for 3 seconds)
- App shows "Confirm pairing" with device name
- Accept/Reject prompt

**Authorization enforcement:**
- Store bonded device UUID in app; reject commands from unknown devices
- ESP32 can pair with only one device at a time (single-user model)

### Command Deduplication

**Problem**: Button bounce or BLE retransmit can cause duplicate commands (e.g., double volume-up).

**Solution**: Sequence number tracking
```dart
class BLEManager {
  int lastSeq = -1;
  
  void onCommandReceived(Map<String, dynamic> cmd) {
    final seq = cmd['seq'] as int;
    if (seq <= lastSeq) {
      print("Duplicate command seq=$seq, ignoring");
      return;
    }
    lastSeq = seq;
    dispatchCommand(cmd);
  }
}
```

**Additional safeguards:**
- Time-based dedup: ignore commands with identical `cmd` within 300ms window
- Long-press events include `"long": true` flag to differentiate from short press

### Graceful Degradation

**Unknown commands:**
```dart
default:
  print("Unknown remote command: $cmdType");
  // Optional: log telemetry but do not crash
  bleManager.sendStatus({"error": "unknown_cmd", "cmd": cmdType});
```

**Connection loss:**
- App shows "Remote disconnected" transient toast (non-blocking)
- Remote LED blinks red; re-enters advertising mode after 30s timeout
- App auto-reconnects when remote is back in range

**Low battery:**
- ESP32 monitors battery voltage via ADC (voltage divider)
- When <15%, send `{"cmd":"battery_low","percent":12}` → app shows persistent notification

---

## Testing Strategy

### 1. Simulated Remote (BLE Emulator)

**Tool**: nRF Connect (iOS/Android) or LightBlue (iOS)

**Test procedure:**
1. Configure nRF Connect as BLE peripheral with custom service UUID
2. Add Command TX characteristic (Notify)
3. Manually send JSON payloads: `{"cmd":"play_pause","seq":1}`
4. Verify app responds within <300ms

**Coverage:**
- All 10+ command types
- Sequence number wraparound (seq=65535 → seq=0)
- Malformed JSON (missing `cmd` field) → graceful ignore

### 2. Latency Validation

**Setup**: Physical ESP32 remote + oscilloscope or logic analyzer

**Method:**
- Attach probe to button GPIO and BLE TX antenna (or sniff BLE packets)
- Measure time from button press (GPIO LOW) to app action visible on screen (use high-speed camera or screen recording at 240fps)

**Acceptance criteria:**
- **Button press → BLE notify sent**: <50ms (firmware)
- **BLE notify → app state update**: <150ms (BLE stack + app processing)
- **Total end-to-end latency**: <300ms (user perceivable threshold: 100–200ms for "instant" feel)

**Optimization if needed:**
- Reduce BLE connection interval (default 30ms → 15ms) via connection parameters
- Use BLE5 if available (lower latency mode)

### 3. Battery Life Test

**Accelerated test (1-week simulation):**
- Configure ESP32 to simulate 100 button presses/day (trigger via timer every 15 minutes)
- Measure battery voltage daily via ADC
- Extrapolate to depletion

**Real-world test:**
- Deploy to 3–5 beta users
- Collect telemetry (button presses/day, connection uptime, battery % over time)
- Target: 6+ months on CR2032 with typical use (20 presses/day, 2h connected/day)

### 4. Integration Tests (Automated)

**Mobile app test suite additions:**

```dart
testWidgets('Remote play_pause command toggles playback', (tester) async {
  // Arrange
  final mockBLE = MockBLEManager();
  await tester.pumpWidget(MyApp(bleManager: mockBLE));
  
  // Act
  mockBLE.simulateCommand('{"cmd":"play_pause","seq":1}');
  await tester.pump();
  
  // Assert
  expect(find.byIcon(Icons.pause), findsOneWidget);
});

test('Command deduplication ignores repeat seq', () {
  final manager = BLEManager();
  manager.handleCommand('{"cmd":"volume_up","seq":5}');
  final vol1 = playbackState.volume;
  
  manager.handleCommand('{"cmd":"volume_up","seq":5}'); // Duplicate
  final vol2 = playbackState.volume;
  
  expect(vol1, vol2); // Volume unchanged
});
```

### 5. Multi-Device Pairing Conflict Test

**Scenario**: Two remotes paired simultaneously (or remote + screen input)

**Expected behavior**:
- App accepts commands from last-paired remote only (single-active-remote policy)
- OR: App accepts commands from multiple remotes (if use case justifies, e.g., multi-user scenario)

**Test**:
1. Pair Remote A → send command → verify works
2. Pair Remote B (without unpairing A) → send command → verify works
3. Send command from A → verify (rejected or accepted based on policy)

---

## Updated Development Roadmap

### Phase 1: Core Playback (MVP) — 2–3 sprints
*(Unchanged from original plan)*
- Integrate audio engine, state management, basic UI
- Persist snapshots locally
- Unit tests for state transitions

### **Phase 1.5: Remote Control Prototype (ESP32 + BLE) — 2 sprints** *(NEW)*

**Objectives:**
- Assemble and test ESP32 hardware prototype (breadboard, 8 buttons)
- Develop firmware: debouncing, BLE GATT server, command JSON protocol
- Mobile app: BLE scanner, pairing UI, background listener, command dispatcher
- Validate latency <300ms and basic power consumption

**Deliverables:**
- Working hardware prototype (breadboard or hand-wired PCB)
- Firmware repo (PlatformIO project)
- App BLE module integrated with existing playback state
- Test results: latency measurement, 24h battery drain baseline

**Acceptance criteria:**
- Remote can trigger play/pause, volume, speed, note commands
- Commands execute within 300ms
- App remains functional without remote connected
- Pairing completes in <60s for new users

**Risks & Mitigation:**
- iOS background BLE throttling → Test on real devices early; document latency variance
- Button mechanical failures → Source high-cycle tactile switches (100k+ cycles rated)

### Phase 2: Note-Taking + Local Persistence — 1–2 sprints
*(Modified from original plan)*

**Added scope:**
- **Remote note trigger**: `note` command pauses playback, pre-fills timestamp, opens quick-input modal
- **Voice-to-text**: Integrate platform speech recognition (iOS: `SFSpeechRecognizer`, Android: `SpeechRecognizer`, Web: `webkitSpeechRecognition`)
- Integration test: "Remote button → note saved with correct timestamp"

### Phase 3: Polishing & Sync — 2–4 sprints
*(Unchanged, with additions)*

**Added scope:**
- **Remote firmware OTA**: Over-the-air firmware updates via BLE (use ESP32 OTA partition)
- **Battery telemetry**: Display remote battery % in app settings
- **Multi-language button labels**: Optional laser-engraved icons for international markets

### Phase 4: Extensions & Scale — ongoing
*(Unchanged, with additions)*

**Remote-specific extensions:**
- **Haptic feedback**: Add vibration motor for button press confirmation
- **OLED display**: 0.96" OLED showing current track, battery, connection status
- **Voice note**: Dedicated mic on remote for true hands-free note capture (BLE audio profile or record-and-forward)

---

## Hardware BOM & Cost Scaling

**Prototype (single unit, hand-assembled):**
- $15–20 (dev board, loose components, 3D print)

**Low-volume production (10–50 units):**
- $10–12/unit (custom PCB, bulk components, manual assembly)

**Scale production (500+ units):**
- $6–8/unit (automated assembly, injection-molded enclosure, CR2032 → rechargeable Li-ion option)

**Retail pricing strategy:**
- Sell at $29–39 (4–5× BOM) to cover support, packaging, shipping
- Bundle discount: $10 off when purchased with app subscription (if applicable)

---

## Open Questions & Risks

### 1. iOS Background BLE Limitations

**Question**: Does iOS reliably deliver BLE notifications when app is in background or suspended?

**Research findings**:
- iOS *will* deliver BLE notifications to apps declaring `bluetooth-central` background mode, but with caveats:
  - Notifications delivered with 200–500ms latency (vs. 50ms foreground)
  - If app is force-quit by user, BLE is disabled until app reopens
  - System may deprioritize BLE updates under low battery or memory pressure

**Mitigation**:
- Educate users: "Keep app in background (not force-quit) for remote to work"
- Optional: Use audio playback background mode (already needed for playback) to keep app alive
- Test extensively on iOS 15, 16, 17+ with different device states

**Risk level**: MEDIUM (manageable with user education and testing)

### 2. Android Permission Requirements

**Question**: What permissions are required for BLE scanning and background operation on Android 12+?

**Requirements**:
- `BLUETOOTH_SCAN` (runtime permission, Android 12+)
- `BLUETOOTH_CONNECT` (runtime permission, Android 12+)
- `ACCESS_FINE_LOCATION` (for BLE scan on Android <12)
- Foreground service with notification (for background BLE listener)

**User friction**:
- Multi-step permission flow (location → Bluetooth → notification)
- Some users deny location permission, blocking BLE scan

**Mitigation**:
- Clear in-app education: "Location permission is required by Android for Bluetooth, but we don't track your location"
- Graceful degradation: If permissions denied, show "Remote pairing unavailable" with retry option
- Use `neverForLocation` flag (Android 12+) to skip location permission if possible

**Risk level**: LOW (standard Android BLE app challenge; well-documented solutions)

### 3. Multi-Device Pairing Conflicts

**Question**: What happens if user pairs multiple remotes or uses remote + screen simultaneously?

**Scenarios**:
- **Scenario A**: User has two remotes (e.g., car remote + desk remote)
- **Scenario B**: User presses screen button *and* remote button at same instant

**Design decisions**:
- **Option 1 (simple)**: Single-remote pairing. Pairing new remote unpairs old one. Command conflict resolved by sequence number (later seq wins).
- **Option 2 (advanced)**: Multi-remote support. Each remote has unique ID; app tracks separate seq per remote. Commands interleave safely via timestamp ordering.

**Recommendation for Phase 1.5**: Option 1 (single remote). Add Option 2 in Phase 4 if user demand exists.

**Risk level**: LOW (design decision; mitigated by clear pairing UX)

### 4. BLE Range & Interference

**Question**: What is effective range, and how does it degrade with obstacles?

**Expected range**:
- Open air: 10–30 meters (BLE Class 2)
- Through body/furniture: 5–10 meters
- Interference from Wi-Fi, microwave: Possible packet loss or latency spikes

**Mitigation**:
- Use BLE5 long-range mode if ESP32-C3 or newer (doubles range at cost of throughput)
- Implement command retry: If no ACK received within 500ms, retransmit (ESP32 side)
- Visual feedback: Remote LED blinks red on connection loss

**Risk level**: LOW (BLE range sufficient for typical use; retry handles transient drops)

### 5. Accidental Presses (Pocket/Bag)

**Question**: How to prevent unintended commands when remote is in pocket?

**Solutions**:
- **Hardware**: Recessed buttons or protective cover
- **Firmware**: "Lock mode" activated by long-press on two buttons simultaneously; LED indicates locked state
- **App**: Setting to ignore remote commands when screen is locked (optional)

**Risk level**: LOW (solvable with mechanical design and firmware lock)

---

## Reference Implementations & Resources

**Open-source ESP32 BLE examples:**
- [ESP32 BLE Arduino Examples](https://github.com/nkolban/ESP32_BLE_Arduino)
- [NimBLE-Arduino Library](https://github.com/h2zero/NimBLE-Arduino) (recommended for lower memory footprint)

**Mobile BLE libraries:**
- Flutter: [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus)
- React Native: [react-native-ble-plx](https://github.com/dotintent/react-native-ble-plx)
- iOS native: Core Bluetooth framework
- Android native: `android.bluetooth.le` package

**3D printable enclosure inspiration:**
- [ESP32 Wemos Button Remote](https://www.printables.com/model/123456) (example, adapt as needed)
- [Ergonomic Gamepad Shell for ESP32](https://www.thingiverse.com/thing:3456789)

**Power profiling tools:**
- [Nordic Power Profiler Kit II](https://www.nordicsemi.com/Products/Development-hardware/Power-Profiler-Kit-2) (measure µA-level current draw)
- Multimeter + data logging for long-term battery tests

---

## Implementation Checklist (Engineering Kickoff)

### Hardware Team
- [ ] Source ESP32 modules and tactile switches
- [ ] Design schematic (Fritzing or KiCad)
- [ ] Prototype on breadboard, test all button inputs
- [ ] Order custom PCB (or use perfboard for initial batch)
- [ ] 3D model enclosure, print prototype, iterate fit
- [ ] Assemble 5 test units for beta

### Firmware Team
- [ ] Set up PlatformIO project with NimBLE-Arduino library
- [ ] Implement button debouncing and long-press detection
- [ ] Implement BLE GATT service and command characteristic
- [ ] Add deep sleep power management
- [ ] Battery voltage monitoring via ADC
- [ ] OTA update mechanism (Phase 3)
- [ ] Unit tests for debouncing logic (simulate GPIO states)

### Mobile App Team
- [ ] Add BLE permissions to manifests (iOS Info.plist, Android AndroidManifest.xml)
- [ ] Implement BLE scanner and pairing UI
- [ ] Background BLE service/listener (platform-specific)
- [ ] Command parser and dispatcher module
- [ ] Update state management to handle remote input
- [ ] Quick-note modal triggered by remote
- [ ] Integration tests: mock BLE commands → verify state changes
- [ ] User settings: pair/unpair remote, battery display

### Testing & QA
- [ ] Latency measurement setup (oscilloscope or logic analyzer)
- [ ] 24-hour battery drain test (accelerated simulation)
- [ ] Multi-platform testing: iOS 15/16/17, Android 11/12/13, web (Chrome)
- [ ] Edge case tests: connection loss, malformed commands, rapid button spam
- [ ] Accessibility validation: remote usable by blind users (tactile feedback, screen reader pairing flow)

### Documentation
- [ ] User manual: pairing instructions, button layout diagram, troubleshooting
- [ ] Developer docs: firmware API, BLE protocol spec, command reference
- [ ] Assembly guide for hardware (if kit model)

---

## Conclusion

The ESP32-based hardware remote transforms the audio player into a truly accessible, hands-free system. By leveraging BLE and a simple command protocol, the remote integrates seamlessly with the existing state architecture defined in `Audio_player.md`—acting as an alternative input source without disrupting the single-source-of-truth model.

**Key strengths:**
- **Low cost** (~$8 BOM) and **long battery life** (6+ months on coin cell) make it viable for mass production.
- **Open-source firmware and hardware** foster community contributions (custom button layouts, enclosure variants).
- **Accessibility and safety** benefits position the product for education, driving, and assistive-tech markets.
- **Phased rollout** (Phase 1.5 prototype → Phase 2 integration → Phase 3 polish) minimizes risk and allows iterative user feedback.

**Next steps for engineering kickoff:**
1. Assemble breadboard prototype and validate button + BLE basics (1 week).
2. Develop mobile BLE module and test with nRF Connect emulator (1 week).
3. Integrate remote command dispatcher with existing playback state (1 week).
4. Conduct latency and battery tests; iterate firmware power management (1 week).
5. Design and print enclosure prototype; refine ergonomics (ongoing).

This remote is not just a peripheral—it's a physical manifestation of the app's state contract, making audio control intuitive, inclusive, and infrastructure-light.
