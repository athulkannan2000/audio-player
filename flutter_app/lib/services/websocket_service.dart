// websocket_service.dart
// WiFi WebSocket service for ESP32 Audio Remote
// Replace your BLE service with this

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // ESP32 connection settings
  String _remoteHost = '192.168.4.1'; // Default AP mode IP
  int _remotePort = 81;

  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _error;

  // Device status
  double? _batteryVoltage;
  int? _signalStrength; // RSSI
  String? _deviceIp;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get error => _error;
  double? get batteryVoltage => _batteryVoltage;
  int? get signalStrength => _signalStrength;
  String? get deviceIp => _deviceIp;
  String get remoteHost => _remoteHost;

  // Callbacks for commands
  Function()? onPlayPause;
  Function()? onNext;
  Function()? onPrevious;
  Function()? onVolumeUp;
  Function()? onVolumeDown;
  Function()? onSpeedCycle;
  Function()? onRepeatCycle;
  Function(int timestamp)? onNote;
  Function(double voltage)? onLowBattery;

  /// Connect to ESP32 WebSocket server
  ///
  /// [host] - IP address of ESP32 (default: 192.168.4.1 for AP mode)
  /// [port] - WebSocket port (default: 81)
  Future<bool> connect({String? host, int? port}) async {
    if (_isConnected || _isConnecting) {
      debugPrint('Already connected or connecting');
      return false;
    }

    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      final targetHost = host ?? _remoteHost;
      final targetPort = port ?? _remotePort;

      debugPrint('Connecting to ws://$targetHost:$targetPort');

      final uri = Uri.parse('ws://$targetHost:$targetPort');
      _channel = WebSocketChannel.connect(uri);

      // Wait for connection (with timeout)
      await _channel!.ready.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

      // Listen for messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _remoteHost = targetHost;
      _remotePort = targetPort;
      _isConnected = true;
      _isConnecting = false;
      _error = null;

      debugPrint('✅ Connected to ESP32!');
      notifyListeners();

      // Request initial status
      await Future.delayed(const Duration(milliseconds: 500));
      _sendCommand('get_status');

      return true;
    } catch (e) {
      debugPrint('❌ Connection failed: $e');
      _error = e.toString();
      _isConnected = false;
      _isConnecting = false;
      _channel = null;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from ESP32
  void disconnect() {
    debugPrint('Disconnecting from ESP32...');
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
  }

  /// Send a command to ESP32 (for testing or custom commands)
  void _sendCommand(String command) {
    if (!_isConnected || _channel == null) {
      debugPrint('Not connected, cannot send command');
      return;
    }

    try {
      final message = jsonEncode({'cmd': command});
      _channel!.sink.add(message);
      debugPrint('Sent: $message');
    } catch (e) {
      debugPrint('Error sending command: $e');
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      debugPrint('Received: $message');

      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final cmd = data['cmd'] as String?;

      if (cmd == null) return;

      switch (cmd) {
        case 'play_pause':
          onPlayPause?.call();
          break;

        case 'next':
          onNext?.call();
          break;

        case 'prev':
          onPrevious?.call();
          break;

        case 'volume_up':
          onVolumeUp?.call();
          break;

        case 'volume_down':
          onVolumeDown?.call();
          break;

        case 'speed_cycle':
          onSpeedCycle?.call();
          break;

        case 'repeat_cycle':
          onRepeatCycle?.call();
          break;

        case 'note':
          final timestamp = data['timestamp'] as int?;
          if (timestamp != null) {
            onNote?.call(timestamp);
          }
          break;

        case 'low_battery':
          final voltage = data['voltage'] as double?;
          if (voltage != null) {
            _batteryVoltage = voltage;
            onLowBattery?.call(voltage);
            notifyListeners();
          }
          break;

        case 'status':
          // Update device status
          _batteryVoltage = data['battery'] as double?;
          _signalStrength = data['rssi'] as int?;
          _deviceIp = data['ip'] as String?;
          notifyListeners();
          break;

        case 'pong':
          // Response to ping - connection is alive
          debugPrint('Ping successful');
          break;

        default:
          debugPrint('Unknown command: $cmd');
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(error) {
    debugPrint('WebSocket error: $error');
    _error = error.toString();
    _isConnected = false;
    notifyListeners();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    debugPrint('WebSocket disconnected');
    _isConnected = false;
    _error = 'Connection lost';
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// Example usage in your Flutter app:
/*

// 1. Add to pubspec.yaml:
dependencies:
  web_socket_channel: ^2.4.0

// 2. Initialize service:
final wsService = WebSocketService();

// 3. Set up callbacks:
wsService.onPlayPause = () {
  // Handle play/pause
  audioPlayer.playPause();
};

wsService.onNext = () {
  audioPlayer.skipToNext();
};

wsService.onPrevious = () {
  audioPlayer.skipToPrevious();
};

wsService.onVolumeUp = () {
  final newVolume = (audioPlayer.volume + 0.1).clamp(0.0, 1.0);
  audioPlayer.setVolume(newVolume);
};

wsService.onVolumeDown = () {
  final newVolume = (audioPlayer.volume - 0.1).clamp(0.0, 1.0);
  audioPlayer.setVolume(newVolume);
};

wsService.onNote = (timestamp) {
  // Create bookmark at timestamp
  createBookmark(timestamp);
};

wsService.onLowBattery = (voltage) {
  // Show low battery warning
  showSnackBar('ESP32 battery low: ${voltage}V');
};

// 4. Connect (AP Mode):
await wsService.connect(); // Uses default 192.168.4.1

// OR Connect (Station Mode with custom IP):
await wsService.connect(host: '192.168.1.100');

// 5. Listen to connection state:
wsService.addListener(() {
  if (wsService.isConnected) {
    print('Connected! Battery: ${wsService.batteryVoltage}V');
  } else if (wsService.error != null) {
    print('Error: ${wsService.error}');
  }
});

// 6. Disconnect when done:
wsService.disconnect();

*/

// Connection UI example:
/*

class RemoteConnectionScreen extends StatefulWidget {
  @override
  _RemoteConnectionScreenState createState() => _RemoteConnectionScreenState();
}

class _RemoteConnectionScreenState extends State<RemoteConnectionScreen> {
  final _wsService = WebSocketService();
  final _ipController = TextEditingController(text: '192.168.4.1');
  
  @override
  void initState() {
    super.initState();
    _wsService.addListener(_onConnectionChange);
  }
  
  void _onConnectionChange() {
    setState(() {});
  }
  
  Future<void> _connect() async {
    final success = await _wsService.connect(
      host: _ipController.text,
    );
    
    if (success) {
      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(wsService: _wsService),
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: ${_wsService.error}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connect to Remote')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'WiFi Connection',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 32),
            
            // Instructions for AP Mode
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Connect to WiFi:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('   SSID: AudioRemote_ESP32'),
                    Text('   Password: audio12345'),
                    SizedBox(height: 8),
                    Text('2. Return to app and tap Connect'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // IP Address input (optional, for Station mode)
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'ESP32 IP Address',
                hintText: '192.168.4.1',
                border: OutlineInputBorder(),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Connect button
            ElevatedButton.icon(
              onPressed: _wsService.isConnecting ? null : _connect,
              icon: _wsService.isConnecting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.wifi),
              label: Text(_wsService.isConnecting ? 'Connecting...' : 'Connect'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            
            // Error display
            if (_wsService.error != null) ...[
              SizedBox(height: 16),
              Text(
                'Error: ${_wsService.error}',
                style: TextStyle(color: Colors.red),
              ),
            ],
            
            // Status
            if (_wsService.isConnected) ...[
              SizedBox(height: 16),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      SizedBox(height: 8),
                      Text('Connected!'),
                      if (_wsService.batteryVoltage != null)
                        Text('Battery: ${_wsService.batteryVoltage!.toStringAsFixed(2)}V'),
                      if (_wsService.signalStrength != null)
                        Text('Signal: ${_wsService.signalStrength} dBm'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _wsService.removeListener(_onConnectionChange);
    _ipController.dispose();
    super.dispose();
  }
}

*/
