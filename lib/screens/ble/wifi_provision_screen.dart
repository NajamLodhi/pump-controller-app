import 'package:flutter/material.dart';
import '../../services/ble_client.dart';
import '../../services/device_registry.dart';

class WiFiProvisionScreen extends StatefulWidget {
  final PumpControllerBleClient client;

  const WiFiProvisionScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<WiFiProvisionScreen> createState() => _WiFiProvisionScreenState();
}

class _WiFiProvisionScreenState extends State<WiFiProvisionScreen> {
  final _registry = DeviceRegistry();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  final List<String> _ssidList = [];
  String? _selectedSsid;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _registry.initialize();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _scanWifi() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Scanning Wi-Fi networks...';
      _isError = false;
    });

    try {
      // Listen for responses
      final responseSubscription = widget.client.onNotify.listen((message) {
        // Parse SSID list response format: SSID,RSSI
        if (message.contains(',')) {
          final parts = message.split(',');
          if (parts.length >= 2) {
            final ssid = parts[0].trim();
            if (ssid.isNotEmpty && !_ssidList.contains(ssid)) {
              setState(() {
                _ssidList.add(ssid);
              });
            }
          }
        }
      });

      // Send scan command
      await widget.client.scanWifi();

      // Wait for responses
      await Future.delayed(const Duration(seconds: 5));
      responseSubscription.cancel();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = _ssidList.isEmpty
              ? 'No networks found. Try again.'
              : 'Found ${_ssidList.length} network(s)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error scanning: $e';
          _isError = true;
        });
      }
    }
  }

  Future<void> _connectToWifi() async {
    final ssid = _selectedSsid ?? _ssidController.text;
    final password = _passwordController.text;

    if (ssid.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter SSID and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to Wi-Fi...';
      _isError = false;
    });

    try {
      bool connected = false;
      String? connectedIp;

      // Listen for connection response
      final responseSubscription = widget.client.onNotify.listen((message) {
        if (message.startsWith('CONNECTED')) {
          // Parse: CONNECTED <ip>
          final parts = message.split(' ');
          if (parts.length >= 2) {
            connectedIp = parts[1].trim();
            connected = true;
          }
        } else if (message.startsWith('CONNECT_FAILED')) {
          connected = false;
        }
      });

      // Send join command
      await widget.client.joinWifi(ssid, password);

      // Wait for response
      int attempts = 0;
      while (!connected && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      responseSubscription.cancel();

      if (mounted) {
        if (connected && connectedIp != null) {
          // Store device IP
          await _registry.storeDevice(widget.client.uid, connectedIp!);

          setState(() {
            _isLoading = false;
            _statusMessage = 'Connected! IP: $connectedIp';
            _isError = false;
          });

          // Show success dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Wi-Fi Connected'),
                content: Text('Device IP: $connectedIp'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Connection failed. Try again.';
            _isError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error: $e';
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Provisioning'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scan button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _scanWifi,
                icon: const Icon(Icons.wifi_find),
                label: const Text('Scan Wi-Fi Networks'),
              ),
            ),
            const SizedBox(height: 16),

            // Status message
            if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isError ? Icons.error : Icons.info,
                      color: _isError ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_statusMessage!),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // SSID selection
            if (_ssidList.isNotEmpty) ...[
              const Text(
                'Select Network',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedSsid,
                  hint: const Text('  Choose a network...'),
                  isExpanded: true,
                  items: _ssidList
                      .map((ssid) => DropdownMenuItem(
                            value: ssid,
                            child: Text(ssid),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedSsid = value);
                  },
                ),
              ),
            ] else ...[
              const Text(
                'Enter Network SSID',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ssidController,
                decoration: InputDecoration(
                  hintText: 'Network name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Password input
            const Text(
              'Password',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: 'Wi-Fi password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // Connect button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _connectToWifi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect to Wi-Fi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
