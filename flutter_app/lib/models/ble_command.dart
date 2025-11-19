/// Model representing a BLE command from ESP32 remote
class BLECommand {
  final String cmd;
  final int seq;
  final int? timestamp;
  final int? positionMs;

  const BLECommand({
    required this.cmd,
    required this.seq,
    this.timestamp,
    this.positionMs,
  });

  factory BLECommand.fromJson(Map<String, dynamic> json) {
    return BLECommand(
      cmd: json['cmd'] as String,
      seq: json['seq'] as int,
      timestamp: json['timestamp'] as int?,
      positionMs: json['ts'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cmd': cmd,
      'seq': seq,
      if (timestamp != null) 'timestamp': timestamp,
      if (positionMs != null) 'ts': positionMs,
    };
  }
}

/// BLE connection state
enum BLEConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}
