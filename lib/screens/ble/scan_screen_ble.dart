import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../services/ble_client.dart';
import 'control_screen_ble.dart';

class ScanScreenBLE extends StatefulWidget {
  const ScanScreenBLE({Key? key}) : super(key: key);

  @override
  State<ScanScreenBLE> createState() => _ScanScreenBLEState();
}

class _ScanScreenBLEState extends State<ScanScreenBLE> {
  final Map<String, BluetoothDevice> _devices = {};
  final Map<String, bool> _selectedDevices = {};
  final Map<String, PumpControllerBleClient> _connectedClients = {};
  bool _isScanning = false;
  bool _isConnecting = false;
  StreamSubscription? _scanResultsSubscription;
  StreamSubscription? _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _stopScan();
    super.dispose();
  }

  void _startScan() {
    if (_isConnecting) return;

    print('[BLE SCAN] Starting scan without service UUID filter...');
    setState(() => _isScanning = true);
    
    // Scan all devices - don't filter by service UUID as PumpController may not advertise it
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );

    // Cancel previous subscriptions
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      print('[BLE SCAN] Received ${results.length} scan results');
      for (var result in results) {
        // Read from advertisementData which is populated during scan
        // device.advName is often empty on Android until connected
        final advName = result.advertisementData.advName;
        final localName = result.advertisementData.localName;
        final displayName = advName.isNotEmpty ? advName : localName;
        final serviceUuids = result.advertisementData.serviceUuids;
        final rssi = result.rssi;
        
        print('[BLE SCAN] Device detected: "$displayName" | MAC: ${result.device.remoteId.str} | RSSI: $rssi | UUIDs: $serviceUuids');
        
        // Check if this is a PumpController device
        final isPumpController = displayName.startsWith('PumpController_') || 
                          displayName.contains('PumpController') ||
                          serviceUuids.any((uuid) => uuid.str.toLowerCase().contains('6e400001'));
        
        if (isPumpController) {
          print('[BLE SCAN] ✓ FOUND PumpController device: $displayName');
          setState(() {
            _devices[result.device.remoteId.str] = result.device;
            _selectedDevices.putIfAbsent(result.device.remoteId.str, () => false);
          });
        }
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!mounted) return;
      print('[BLE SCAN] isScanning changed to: $isScanning');
      if (!isScanning) {
        print('[BLE SCAN] Scan completed, total devices found: ${_devices.length}');
        setState(() => _isScanning = false);
      }
    });
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    setState(() => _isScanning = false);
  }

  Future<void> _toggleDeviceConnection(String deviceId) async {
    final device = _devices[deviceId];
    if (device == null) return;

    final isCurrentlySelected = _selectedDevices[deviceId] ?? false;

    try {
      if (isCurrentlySelected) {
        // Disconnect
        setState(() => _isConnecting = true);
        if (_connectedClients.containsKey(deviceId)) {
          await _connectedClients[deviceId]!.disconnect();
          _connectedClients.remove(deviceId);
        }
        setState(() {
          _selectedDevices[deviceId] = false;
          _isConnecting = false;
        });
      } else {
        // Connect
        setState(() => _isConnecting = true);
        _stopScan(); // Stop scan before connecting

        final client = PumpControllerBleClient(device);
        await client.connect();

        setState(() {
          _selectedDevices[deviceId] = true;
          _connectedClients[deviceId] = client;
          _isConnecting = false;
        });
      }
    } catch (e) {
      setState(() => _isConnecting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }

  void _navigateToControl() {
    final selectedClients = _connectedClients.entries
        .where((e) => _selectedDevices[e.key] ?? false)
        .map((e) => e.value)
        .toList();

    if (selectedClients.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ControlScreenBLE(clients: selectedClients),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedCount =
        _selectedDevices.values.where((v) => v).length;
    final hasConnected = connectedCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan BLE Devices'),
        actions: [
          if (_isScanning && !_isConnecting)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth_disabled, size: 48),
                  const SizedBox(height: 16),
                  const Text('No PumpController devices found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isConnecting ? null : _startScan,
                    child: const Text('Scan Again'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final deviceId = _devices.keys.elementAt(index);
                final device = _devices[deviceId]!;
                final isSelected = _selectedDevices[deviceId] ?? false;
                final isConnecting =
                    _isConnecting && isSelected;

                return ListTile(
                  title: Text(device.advName),
                  subtitle: Text(device.remoteId.str),
                  trailing: isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        )
                      : Icon(
                          isSelected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                  onTap: _isConnecting
                      ? null
                      : () => _toggleDeviceConnection(deviceId),
                );
              },
            ),
      floatingActionButton: hasConnected && !_isConnecting
          ? FloatingActionButton(
              onPressed: _navigateToControl,
              child: const Icon(Icons.arrow_forward),
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}
