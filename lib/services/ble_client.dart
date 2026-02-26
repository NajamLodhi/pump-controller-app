import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Wraps a single connected BluetoothDevice for ReefFlow control
class ReefFlowBleClient {
  final BluetoothDevice device;
  late String _uid;
  late BluetoothCharacteristic _cmdChar; // 6E400002-B5A3-F393-E0A9-E50E24DCCA9E
  late BluetoothCharacteristic _respChar; // 6E400003-B5A3-F393-E0A9-E50E24DCCA9E
  late BluetoothCharacteristic _uidChar; // 6E400004-B5A3-F393-E0A9-E50E24DCCA9E

  StreamSubscription? _notifySubscription;
  final _responseController = StreamController<String>.broadcast();

  // UUIDs for ReefFlow service and characteristics
  static const serviceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const cmdCharUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const respCharUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
  static const uidCharUuid = '6e400004-b5a3-f393-e0a9-e50e24dcca9e';

  ReefFlowBleClient(this.device);

  String get uid => _uid;
  Stream<String> get onNotify => _responseController.stream;

  /// Connect and discover services
  Future<void> connect() async {
    await device.connect();
    await _discoverServices();
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    _responseController.close();
    await device.disconnect();
  }

  /// Discover services and cache characteristics
  Future<void> _discoverServices() async {
    final services = await device.discoverServices();

    final reefService = services.firstWhere(
      (s) => s.uuid.toString().toLowerCase() == serviceUuid,
      orElse: () => throw Exception('ReefFlow service not found'),
    );

    // Find characteristics
    _cmdChar = reefService.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase() == cmdCharUuid,
      orElse: () => throw Exception('Command characteristic not found'),
    );

    _respChar = reefService.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase() == respCharUuid,
      orElse: () => throw Exception('Response characteristic not found'),
    );

    _uidChar = reefService.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase() == uidCharUuid,
      orElse: () => throw Exception('UID characteristic not found'),
    );

    // Read UID
    final uidData = await _uidChar.read();
    _uid = String.fromCharCodes(uidData);

    // Subscribe to notify characteristic
    await _respChar.setNotifyValue(true);
    _notifySubscription = _respChar.onValueReceived.listen((value) {
      final message = String.fromCharCodes(value);
      // Parse line-by-line responses
      final lines = message.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          _responseController.add(line);
        }
      }
    });
  }

  /// Send command string via BLE
  Future<void> send(String command) async {
    final bytes = command.codeUnits;
    try {
      // Try writing with response first
      await _cmdChar.write(bytes);
    } catch (e) {
      // If that fails, try without response
      // print('Write failed, trying without response: $e');
    }
  }

  /// Set wave mode (0=Sine, 1=Pulse, 2=Constant)
  Future<void> setWaveMode(int waveMode) async {
    await send('01 $waveMode');
  }

  /// Set speed (0-100)
  Future<void> setSpeed(int speed) async {
    await send('05 $speed');
  }

  /// Set feed mode (minutes, 0 to cancel)
  Future<void> setFeedMode(int minutes) async {
    await send('02 $minutes');
  }

  /// Scan Wi-Fi networks
  Future<void> scanWifi() async {
    await send('10 SCAN');
  }

  /// Join Wi-Fi network
  Future<void> joinWifi(String ssid, String password) async {
    await send('11 $ssid,$password');
  }
}
