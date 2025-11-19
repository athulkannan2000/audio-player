import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ble_service.dart';
import '../models/ble_command.dart';

class BLEPairingScreen extends ConsumerStatefulWidget {
  const BLEPairingScreen({super.key});

  @override
  ConsumerState<BLEPairingScreen> createState() => _BLEPairingScreenState();
}

class _BLEPairingScreenState extends ConsumerState<BLEPairingScreen> {
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check Bluetooth permissions
    final bleService = ref.read(bleServiceProvider);
    final isAvailable = await bleService.isBluetoothAvailable();
    
    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth is not available or not enabled'),
          ),
        );
      }
      return;
    }

    // Request permissions (Android)
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final bleService = ref.read(bleServiceProvider);
      await bleService.startScanning();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _stopScanning() async {
    final bleService = ref.read(bleServiceProvider);
    await bleService.stopScanning();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final bleService = ref.read(bleServiceProvider);
    
    try {
      await _stopScanning();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connecting...')),
        );
      }

      await bleService.connect(device);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(bleConnectionStateProvider);
    final bleService = ref.watch(bleServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair ESP32 Remote'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: connectionState.when(
              data: (state) {
                if (state == BLEConnectionState.connected) {
                  final device = bleService.connectedDevice;
                  return Card(
                    color: Colors.green[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Connected',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(device?.name ?? 'Unknown Device'),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await bleService.disconnect();
                            },
                            child: const Text('Disconnect'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return FilledButton.icon(
                  onPressed: _isScanning ? _stopScanning : _startScanning,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ),
          
          const Divider(),
          
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: bleService.scanResults,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning
                              ? 'Scanning for devices...'
                              : 'No devices found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure your ESP32 remote is powered on',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final devices = snapshot.data!;
                
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final result = devices[index];
                    final device = result.device;
                    final rssi = result.rssi;
                    final name = device.name.isNotEmpty 
                        ? device.name 
                        : 'Unknown Device';

                    // Highlight AudioRemote devices
                    final isAudioRemote = name.contains('AudioRemote');

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: isAudioRemote
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: isAudioRemote
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isAudioRemote
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${device.id}\nSignal: $rssi dBm',
                        ),
                        trailing: FilledButton(
                          onPressed: () => _connectToDevice(device),
                          child: const Text('Connect'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
