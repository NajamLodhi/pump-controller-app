import 'package:flutter/material.dart';
import '../../services/ble_client.dart';
import 'wifi_provision_screen.dart';

class ControlScreenBLE extends StatefulWidget {
  final List<ReefFlowBleClient> clients;

  const ControlScreenBLE({Key? key, required this.clients}) : super(key: key);

  @override
  State<ControlScreenBLE> createState() => _ControlScreenBLEState();
}

class _ControlScreenBLEState extends State<ControlScreenBLE> {
  int _waveMode = 0; // 0=Sine, 1=Pulse, 2=Constant
  int _speed = 50; // 0-100
  bool _isSending = false;

  @override
  void dispose() {
    for (final client in widget.clients) {
      client.disconnect();
    }
    super.dispose();
  }

  Future<void> _sendToAll(Future<void> Function(ReefFlowBleClient) action) async {
    setState(() => _isSending = true);
    try {
      for (final client in widget.clients) {
        await action(client);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _setWaveMode(int mode) {
    setState(() => _waveMode = mode);
    _sendToAll((client) => client.setWaveMode(mode));
  }

  void _setSpeed(int speed) {
    setState(() => _speed = speed);
    _sendToAll((client) => client.setSpeed(speed));
  }

  void _triggerFeed(int minutes) {
    _sendToAll((client) => client.setFeedMode(minutes));
  }

  void _navigateToProvisioning() {
    if (widget.clients.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WiFiProvisionScreen(
            client: widget.clients.first,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Devices (BLE)'),
      ),
      body: AbsorbPointer(
        absorbing: _isSending,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device list
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connected Devices',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.clients.map((client) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '• ${client.uid}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wave mode selector
                  const Text(
                    'Wave Mode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _WaveModeButton(
                        label: 'Sine',
                        mode: 0,
                        isSelected: _waveMode == 0,
                        onPressed: () => _setWaveMode(0),
                      ),
                      _WaveModeButton(
                        label: 'Pulse',
                        mode: 1,
                        isSelected: _waveMode == 1,
                        onPressed: () => _setWaveMode(1),
                      ),
                      _WaveModeButton(
                        label: 'Constant',
                        mode: 2,
                        isSelected: _waveMode == 2,
                        onPressed: () => _setWaveMode(2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Speed slider
                  Text(
                    'Speed: $_speed%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _speed.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) => _setSpeed(value.toInt()),
                  ),
                  const SizedBox(height: 32),

                  // Feed mode buttons
                  const Text(
                    'Feed Mode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _triggerFeed(2),
                          child: const Text('Feed 2 min'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _triggerFeed(5),
                          child: const Text('Feed 5 min'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _triggerFeed(0),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Wi-Fi provisioning button
                  Center(
                    child: ElevatedButton(
                      onPressed: _navigateToProvisioning,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Setup Wi-Fi (Optional)'),
                    ),
                  ),
                ],
              ),
            ),
            if (_isSending)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaveModeButton extends StatelessWidget {
  final String label;
  final int mode;
  final bool isSelected;
  final VoidCallback onPressed;

  const _WaveModeButton({
    required this.label,
    required this.mode,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
