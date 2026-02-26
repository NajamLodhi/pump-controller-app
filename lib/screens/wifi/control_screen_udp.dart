import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../services/udp_client.dart';

class ControlScreenUDP extends StatefulWidget {
  final List<String> deviceIps;
  final ReefFlowUdpClient udpClient;

  const ControlScreenUDP({
    Key? key,
    required this.deviceIps,
    required this.udpClient,
  }) : super(key: key);

  @override
  State<ControlScreenUDP> createState() => _ControlScreenUDPState();
}

class _ControlScreenUDPState extends State<ControlScreenUDP> {
  int _waveMode = 0; // 0=Sine, 1=Pulse, 2=Constant
  int _speed = 50; // 0-100
  bool _isSending = false;
  String? _phoneIp;
  String? _subnetWarning;

  @override
  void initState() {
    super.initState();
    _checkWifiSubnet();
  }

  Future<void> _checkWifiSubnet() async {
    try {
      final networkInfo = NetworkInfo();
      final ip = await networkInfo.getWifiIP();
      setState(() => _phoneIp = ip);

      if (ip != null && widget.deviceIps.isNotEmpty) {
        final phoneSubnet = _getSubnet(ip);
        final deviceSubnet = _getSubnet(widget.deviceIps.first);

        if (phoneSubnet != deviceSubnet) {
          setState(() => _subnetWarning =
              'Warning: Not on same Wi-Fi subnet! Phone: $phoneSubnet, Device: $deviceSubnet');
        }
      }
    } catch (e) {
      // Silently ignore subnet check errors
    }
  }

  String _getSubnet(String ip) {
    final parts = ip.split('.');
    if (parts.length >= 3) {
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return ip;
  }

  Future<void> _sendToAll(
      Future<void> Function(List<String>) action) async {
    setState(() => _isSending = true);
    try {
      await action(widget.deviceIps);
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
    _sendToAll((ips) => widget.udpClient.broadcastSetWaveMode(ips, mode));
  }

  void _setSpeed(int speed) {
    setState(() => _speed = speed);
    _sendToAll((ips) => widget.udpClient.broadcastSetSpeed(ips, speed));
  }

  void _triggerFeed(int minutes) {
    _sendToAll((ips) => widget.udpClient.broadcastSetFeedMode(ips, minutes));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Devices (UDP)'),
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
                  // Network info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Network Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Phone IP: $_phoneIp',
                              style: const TextStyle(fontSize: 12)),
                          Text('Devices: ${widget.deviceIps.join(", ")}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subnet warning
                  if (_subnetWarning != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _subnetWarning!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
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
