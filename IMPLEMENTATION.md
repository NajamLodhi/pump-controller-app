# PumpController WaveMaker Mobile App

A Flutter application for controlling the PumpController WaveMaker (ESP32) device via Bluetooth (BLE) and Wi-Fi (UDP).

## Features

### BLE Control Flow
- **Scan & Connect**: Automatically discovers nearby PumpController devices (device names starting with `PumpController_`)
- **Multi-device Support**: Connect and control multiple devices simultaneously via BLE
- **Live Control**: Adjust wave mode, speed, and feed settings in real-time
- **Wi-Fi Provisioning**: Optional BLE-based Wi-Fi onboarding to enable UDP control

### Wi-Fi (UDP) Control Flow
- **Automatic Discovery**: Listens for UDP broadcasts from devices already connected to your Wi-Fi network
- **Live Device List**: Shows discovered devices with their UID and IP address
- **Subnet Verification**: Warns if the phone is not on the same Wi-Fi subnet as the devices
- **Broadcast Control**: Send commands to multiple devices simultaneously over UDP

### Device Management
- **Local Storage**: Saves known devices (UID ↔ IP) using SharedPreferences
- **Persistent State**: Remembers last selected control mode

## Architecture

### Services Layer

#### `PumpControllerBleClient` (ble_client.dart)
Wraps individual BLE device connections with:
- Service discovery and characteristic caching
- UID reading from device
- Notification subscription for incoming responses
- Command sending (wave mode, speed, feed)
- Wi-Fi provisioning support

**Key UUIDs (from firmware)**:
- Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- Command TX: `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
- Response RX: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- UID Read: `6E400004-B5A3-F393-E0A9-E50E24DCCA9E`

#### `PumpControllerUdpClient` (udp_client.dart)
Handles UDP communication with:
- Broadcast listening on port 8888
- Discovery message parsing (`UID:<uid>,IP:<ip>`)
- Command broadcasting to multiple devices
- Methods for wave, speed, and feed control

#### `DeviceRegistry` (device_registry.dart)
Manages persistent device storage with:
- Known device list (UID → IP mapping)
- Friendly names (optional)
- Last known IP updates
- SharedPreferences integration

### UI Screens

#### HomeScreen
Entry point with two big buttons:
- "Control via Bluetooth (BLE)"
- "Control via Wi-Fi (Router)"

#### BLE Flow
1. **ScanScreenBLE**: Displays nearby `PumpController_*` devices
   - Shows device name, MAC address, and RSSI
   - Connection state per row (Disconnected/Connecting/Connected)
   - Multi-select capability via tapping rows
   
2. **ControlScreenBLE**: Command interface for connected devices
   - Device list (connected devices shown at top)
   - Wave mode selector (Sine/Pulse/Constant via command `01`)
   - Speed slider (0-100 via command `05`)
   - Feed mode buttons (2/5 min or cancel via command `02`)
   - Progress indicator during sends
   
3. **WiFiProvisionScreen**: Optional BLE-based provisioning
   - Scans available Wi-Fi networks (`10 SCAN`)
   - Shows SSID list
   - Accepts password input
   - Joins network (`11 ssid,pass`)
   - Parses responses: `CONNECTED <ip>` or `CONNECT_FAILED`

#### WiFi (UDP) Flow
1. **DiscoveryScreenUDP**: Listens for UDP broadcasts
   - Shows discovered devices (UID + IP)
   - Multi-select checkboxes
   - Live list updates as devices broadcast
   
2. **ControlScreenUDP**: Same UI as BLE control
   - Network information panel (phone IP + device IPs)
   - Subnet mismatch warning
   - Wave/Speed/Feed controls send to all selected devices

## Command Protocol (BLE & UDP)

Both BLE and UDP use the same ASCII command format:

| Command | Format | Example | Description |
|---------|--------|---------|-------------|
| Wave Mode | `01 <mode>` | `01 0` | 0=Sine, 1=Pulse, 2=Constant |
| Feed Mode | `02 <mins>` | `02 5` | Feed for N minutes; `02 0` cancels |
| Speed | `05 <pct>` | `05 75` | Speed 0-100% |
| Wi-Fi Scan | `10 SCAN` | `10 SCAN` | Scan available SSIDs |
| Wi-Fi Join | `11 <ssid>,<pass>` | `11 MySSID,password123` | Join Wi-Fi network |

**Responses** (via BLE notify or UDP broadcast):
- `SSID,RSSI` – Wi-Fi scan results (multiple lines)
- `CONNECTED <ip>` – Successfully joined Wi-Fi with given IP
- `CONNECT_FAILED` – Wi-Fi join failed
- `UID:<uid>,IP:<ip>` – UDP broadcast from device (sent ~5s intervals)

## Permissions

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<uses-feature
    android:name="android.hardware.bluetooth_le"
    android:required="true" />
```

**Runtime Permissions** (requested in main.dart):
- `BLUETOOTH_CONNECT` (Android 12+)
- `BLUETOOTH_SCAN` (Android 12+)
- `ACCESS_FINE_LOCATION` (required for BLE scan)

### iOS (Runner/Info.plist)
```xml
<key>NSBluetoothCentralUsageDescription</key>
<string>This app needs access to Bluetooth to scan and control PumpController WaveMaker devices.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs access to Bluetooth to connect to PumpController WaveMaker devices.</string>

<key>NSLocalNetworkUsageDescription</key>
<string>This app needs access to the local network to control PumpController WaveMaker devices via Wi-Fi.</string>

<key>NSBonjourServices</key>
<array>
    <string>_pump_controller._udp</string>
</array>
```

## Dependencies

```yaml
flutter_blue_plus: ^1.36.8      # BLE scanning and control
permission_handler: ^12.0.1     # Runtime permissions
network_info_plus: ^5.0.3       # Get phone Wi-Fi IP
shared_preferences: ^2.2.2      # Local device storage
provider: ^6.0.0                # State management (optional)
```

## Installation & Build

### Prerequisites
- Flutter 3.10.1+
- Dart 3.10+
- iOS development environment (Xcode 14+)
- Android development environment (API 21+)

### Getting Started
```bash
# Install dependencies
flutter pub get

# Run analysis
flutter analyze

# Run on device/emulator
flutter run
```

### Building for Release

**Android**:
```bash
flutter build apk
flutter build appbundle
```

**iOS**:
```bash
flutter build ios
```

## Usage Flow

### BLE Control (Device not on Wi-Fi)
1. Start app → Home Screen
2. Tap "Control via Bluetooth"
3. ScanScreenBLE shows nearby devices
4. Tap device(s) to connect
5. Connected devices show in ControlScreenBLE
6. Adjust controls → commands broadcast to all selected devices
7. (Optional) Tap "Setup Wi-Fi" to provision device for UDP mode

### UDP Control (Device on Wi-Fi)
1. Start app → Home Screen
2. Tap "Control via Wi-Fi"
3. DiscoveryScreenUDP listens for device broadcasts
4. Devices appear in list as they broadcast
5. Select device(s)
6. Tap "Control Selected"
7. ControlScreenUDP shows network info and controls

## Testing Checklist

- [ ] BLE scan finds devices named `PumpController_*`
- [ ] Can connect to single device and see UID
- [ ] Wave mode commands (01 x) send successfully
- [ ] Speed slider (05 x) sends 0-100
- [ ] Feed buttons (02 x) send correctly
- [ ] Multiple devices can connect and receive same commands
- [ ] Wi-Fi scan (`10 SCAN`) returns SSID list
- [ ] Wi-Fi join (`11 ssid,pass`) shows `CONNECTED <ip>` response
- [ ] UDP discovery receives and displays device broadcasts
- [ ] UDP control sends commands to selected device IPs
- [ ] Subnet warning appears when phone not on same network
- [ ] App doesn't crash on rescan or rapid connect/disconnect

## Known Limitations

- **ESP32 Wi-Fi**: 2.4GHz only; enterprise networks may fail with status code 4
- **BLE Discovery**: Device may not appear in phone Bluetooth settings; must use app's BLE scan
- **Multi-device BLE**: Connecting to more than 3-4 devices simultaneously may cause instability
- **UDP Broadcast**: Requires device and phone to be on same Wi-Fi network

## Future Enhancements

- Device grouping and saved presets
- Scheduling/automation support
- Enhanced error handling and user feedback
- App widget for quick access
- Support for firmware OTA updates via BLE
- Historical command logging

## License

Proprietary – PumpController, Inc.

## Support

For issues or feature requests, contact the PumpController development team.
