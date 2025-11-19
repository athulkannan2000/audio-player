import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ble_command.dart';

/// BLE Service for communicating with ESP32 remote
class BLEService {
  // Service and Characteristic UUIDs from ESP32 firmware
  static const String serviceUUID = "0000A000-0000-1000-8000-00805F9B34FB";
  static const String commandCharUUID = "0000A001-0000-1000-8000-00805F9B34FB";
  
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  
  final _connectionStateController = StreamController<BLEConnectionState>.broadcast();
  final _commandController = StreamController<BLECommand>.broadcast();
  
  Stream<BLEConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<BLECommand> get commandStream => _commandController.stream;
  
  BLEConnectionState _currentState = BLEConnectionState.disconnected;
  int _lastSeq = -1;
  
  BLEConnectionState get currentState => _currentState;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  
  void _updateState(BLEConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }
  
  /// Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }
  
  /// Start scanning for ESP32 remote
  Future<void> startScanning() async {
    try {
      _updateState(BLEConnectionState.scanning);
      
      // Stop any existing scan
      await FlutterBluePlus.stopScan();
      
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      _updateState(BLEConnectionState.disconnected);
      rethrow;
    }
  }
  
  /// Stop scanning
  Future<void> stopScanning() async {
    await FlutterBluePlus.stopScan();
    if (_currentState == BLEConnectionState.scanning) {
      _updateState(BLEConnectionState.disconnected);
    }
  }
  
  /// Get stream of scanned devices
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  
  /// Connect to a specific device
  Future<void> connect(BluetoothDevice device) async {
    try {
      _updateState(BLEConnectionState.connecting);
      
      // Stop scanning
      await stopScanning();
      
      // Connect to device
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
      
      _connectedDevice = device;
      
      // Discover services
      final services = await device.discoverServices();
      
      // Find our service and characteristic
      for (var service in services) {
        if (service.uuid.toString().toUpperCase() == serviceUUID.toUpperCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == commandCharUUID.toUpperCase()) {
              _commandCharacteristic = characteristic;
              
              // Subscribe to notifications
              await characteristic.setNotifyValue(true);
              
              // Listen to incoming commands
              characteristic.lastValueStream.listen(_handleIncomingCommand);
              
              _updateState(BLEConnectionState.connected);
              return;
            }
          }
        }
      }
      
      // Service or characteristic not found
      await disconnect();
      throw Exception('Audio Remote service not found on device');
      
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }
  
  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } finally {
      _connectedDevice = null;
      _commandCharacteristic = null;
      _updateState(BLEConnectionState.disconnected);
    }
  }
  
  /// Handle incoming command from ESP32
  void _handleIncomingCommand(List<int> value) {
    try {
      final jsonString = utf8.decode(value);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final command = BLECommand.fromJson(json);
      
      // Deduplication check
      if (command.seq <= _lastSeq) {
        // Duplicate command, ignore
        return;
      }
      
      _lastSeq = command.seq;
      _commandController.add(command);
      
    } catch (e) {
      // Malformed command, ignore
    }
  }
  
  /// Send status back to ESP32 (acknowledgment)
  Future<void> sendStatus(Map<String, dynamic> status) async {
    if (_commandCharacteristic == null) return;
    
    try {
      final jsonString = jsonEncode(status);
      final bytes = utf8.encode(jsonString);
      await _commandCharacteristic!.write(bytes);
    } catch (e) {
      // Write failed, ignore
    }
  }
  
  /// Dispose resources
  void dispose() {
    _connectionStateController.close();
    _commandController.close();
    disconnect();
  }
}

/// Provider for BLE service
final bleServiceProvider = Provider<BLEService>((ref) {
  final service = BLEService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for BLE connection state
final bleConnectionStateProvider = StreamProvider<BLEConnectionState>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.connectionStateStream;
});

/// Provider for BLE commands
final bleCommandProvider = StreamProvider<BLECommand>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.commandStream;
});
