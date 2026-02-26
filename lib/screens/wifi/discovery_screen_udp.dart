import 'package:flutter/material.dart';
import '../../services/udp_client.dart';
import 'control_screen_udp.dart';

class DiscoveryScreenUDP extends StatefulWidget {
  const DiscoveryScreenUDP({Key? key}) : super(key: key);

  @override
  State<DiscoveryScreenUDP> createState() => _DiscoveryScreenUDPState();
}

class _DiscoveryScreenUDPState extends State<DiscoveryScreenUDP> {
  final _udpClient = PumpControllerUdpClient();
  final Map<String, UdpDevice> _devices = {};
  final Map<String, bool> _selectedDevices = {};
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  @override
  void dispose() {
    _udpClient.stopListening();
    _udpClient.dispose();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    try {
      await _udpClient.startListening();
      setState(() => _isListening = true);

      // Listen for discovered devices
      _udpClient.onDiscovery.listen((device) {
        setState(() {
          _devices[device.uid] = device;
          _selectedDevices.putIfAbsent(device.uid, () => false);
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting discovery: $e')),
        );
      }
    }
  }

  void _toggleDeviceSelection(String uid) {
    setState(() {
      _selectedDevices[uid] = !(_selectedDevices[uid] ?? false);
    });
  }

  void _navigateToControl() {
    final selectedIps = _devices.entries
        .where((e) => _selectedDevices[e.key] ?? false)
        .map((e) => e.value.ip)
        .toList();

    if (selectedIps.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ControlScreenUDP(
            deviceIps: selectedIps,
            udpClient: _udpClient,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedDevices.values.where((v) => v).length;
    final hasSelected = selectedCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Devices (UDP)'),
        actions: [
          if (_isListening)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Waiting for devices...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make sure PumpController devices are connected to Wi-Fi',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _startDiscovery,
                    child: const Text('Restart Discovery'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final uid = _devices.keys.elementAt(index);
                final device = _devices[uid]!;
                final isSelected = _selectedDevices[uid] ?? false;

                return ListTile(
                  title: Text(device.uid),
                  subtitle: Text(device.ip),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleDeviceSelection(uid),
                  ),
                  onTap: () => _toggleDeviceSelection(uid),
                );
              },
            ),
      floatingActionButton: hasSelected
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
