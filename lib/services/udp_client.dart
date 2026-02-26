import 'dart:async';
import 'dart:io';

/// Client for UDP communication with PumpController devices
class PumpControllerUdpClient {
  late RawDatagramSocket _socket;
  final _discoveryController = StreamController<UdpDevice>.broadcast();
  final int port = 8888;
  bool _isListening = false;

  Stream<UdpDevice> get onDiscovery => _discoveryController.stream;

  /// Start listening for UDP broadcasts
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket.broadcastEnabled = true;
      _isListening = true;

      _socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data);
            _parseDiscoveryMessage(message);
          }
        }
      });
    } catch (e) {
      print('Error starting UDP listener: $e');
      _isListening = false;
    }
  }

  /// Parse discovery message format: UID:<uid>,IP:<ip>
  void _parseDiscoveryMessage(String message) {
    try {
      final parts = message.split(',');
      if (parts.length >= 2) {
        final uidPart = parts[0].split(':');
        final ipPart = parts[1].split(':');

        if (uidPart.length == 2 && ipPart.length == 2) {
          final uid = uidPart[1].trim();
          final ip = ipPart[1].trim();

          if (uid.isNotEmpty && ip.isNotEmpty) {
            _discoveryController.add(UdpDevice(uid: uid, ip: ip));
          }
        }
      }
    } catch (e) {
      // Silently ignore malformed messages
    }
  }

  /// Stop listening for broadcasts
  void stopListening() {
    if (_isListening) {
      _socket.close();
      _isListening = false;
    }
  }

  /// Send command to a single device
  Future<void> sendCommand(String ip, String command) async {
    try {
      _socket.send(
        command.codeUnits,
        InternetAddress(ip),
        port,
      );
    } catch (e) {
      // Silently ignore send errors
    }
  }

  /// Send command to multiple devices
  Future<void> sendCommandToMany(List<String> ips, String command) async {
    for (final ip in ips) {
      await sendCommand(ip, command);
    }
  }

  /// Set wave mode via UDP (0=Sine, 1=Pulse, 2=Constant)
  Future<void> setWaveMode(String ip, int waveMode) async {
    await sendCommand(ip, '01 $waveMode');
  }

  /// Set speed via UDP (0-100)
  Future<void> setSpeed(String ip, int speed) async {
    await sendCommand(ip, '05 $speed');
  }

  /// Set feed mode via UDP (minutes, 0 to cancel)
  Future<void> setFeedMode(String ip, int minutes) async {
    await sendCommand(ip, '02 $minutes');
  }

  /// Broadcast command to all provided IPs
  Future<void> broadcastSetWaveMode(List<String> ips, int waveMode) async {
    await sendCommandToMany(ips, '01 $waveMode');
  }

  /// Broadcast speed command to all provided IPs
  Future<void> broadcastSetSpeed(List<String> ips, int speed) async {
    await sendCommandToMany(ips, '05 $speed');
  }

  /// Broadcast feed mode command to all provided IPs
  Future<void> broadcastSetFeedMode(List<String> ips, int minutes) async {
    await sendCommandToMany(ips, '02 $minutes');
  }

  void dispose() {
    stopListening();
    _discoveryController.close();
  }
}

/// Represents a discovered UDP device
class UdpDevice {
  final String uid;
  final String ip;

  UdpDevice({required this.uid, required this.ip});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UdpDevice && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
