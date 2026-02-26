# ReefFlow WaveMaker App - Project Structure

## Directory Layout

```
lib/
├── main.dart                          # App entry point with permission requests
├── screens/
│   ├── home_screen.dart              # Navigation hub (BLE vs Wi-Fi choice)
│   ├── ble/
│   │   ├── scan_screen_ble.dart      # BLE device discovery and multi-connect
│   │   ├── control_screen_ble.dart   # BLE device control interface
│   │   └── wifi_provision_screen.dart # Wi-Fi onboarding via BLE
│   └── wifi/
│       ├── discovery_screen_udp.dart # UDP device discovery
│       └── control_screen_udp.dart   # UDP device control interface
└── services/
    ├── ble_client.dart               # Single BLE device wrapper
    ├── udp_client.dart               # UDP broadcast/send client
    └── device_registry.dart          # SharedPreferences storage

android/
├── app/
│   ├── src/main/AndroidManifest.xml  # Permissions and feature requirements
│   └── build.gradle.kts              # Build configuration
└── gradle/                           # Gradle configuration

ios/
├── Runner/
│   ├── Info.plist                    # iOS permissions and configurations
│   └── Runner.xcodeproj              # Xcode project file
└── Podfile                           # CocoaPods dependencies

pubspec.yaml                          # Flutter dependencies and configuration
```

## Key Files

### lib/main.dart
- Initializes Flutter
- Requests runtime permissions (BLE + location)
- Sets up Material 3 theme
- Navigates to HomeScreen

### lib/screens/home_screen.dart
- Two large centered buttons for BLE and Wi-Fi flows
- Entry point for app navigation

### lib/screens/ble/scan_screen_ble.dart
- Scans for `ReefFlow_*` BLE devices
- Displays device name, MAC ID, RSSI
- Shows connection state (Disconnected/Connecting/Connected)
- Multi-select by tapping rows
- Stops scan before connecting to prevent conflicts
- Navigates to ControlScreenBLE when ≥1 device connected

### lib/screens/ble/control_screen_ble.dart
- Shows list of connected devices at top
- Three wave mode buttons (Sine/Pulse/Constant)
- Speed slider (0-100%)
- Feed mode buttons (2 min / 5 min / Cancel)
- Progress indicator while sending
- Optional "Setup Wi-Fi" button for provisioning

### lib/screens/ble/wifi_provision_screen.dart
- Sends `10 SCAN` command to single BLE device
- Displays SSID list from responses
- User selects SSID and enters password
- Sends `11 ssid,password` command
- Listens for `CONNECTED <ip>` or `CONNECT_FAILED` responses
- Stores device IP in registry on success
- Allows retry on failure

### lib/screens/wifi/discovery_screen_udp.dart
- Starts UDP listener on port 8888
- Parses discovery messages: `UID:<uid>,IP:<ip>`
- Displays discovered devices in list
- Checkbox multi-selection
- Navigates to ControlScreenUDP with selected device IPs

### lib/screens/wifi/control_screen_udp.dart
- Shows phone IP and device IPs
- Checks Wi-Fi subnet (first 3 octets match)
- Shows warning if mismatch
- Same controls as BLE (wave, speed, feed)
- Broadcasts commands to all selected device IPs

### lib/services/ble_client.dart
- Wraps `BluetoothDevice` for single device control
- Discovers services and caches characteristics
- Reads UID from device
- Subscribes to notifications
- Methods: `connect()`, `disconnect()`, `send(cmd)`, `setWaveMode()`, `setSpeed()`, `setFeedMode()`, `scanWifi()`, `joinWifi()`
- Stream: `onNotify` for incoming responses

### lib/services/udp_client.dart
- Binds to UDP port 8888
- Listens for device broadcasts
- Parses discovery messages
- Sends commands to device IPs
- Methods: `startListening()`, `stopListening()`, `sendCommand()`, `sendCommandToMany()`
- Broadcasting methods: `broadcastSetWaveMode()`, `broadcastSetSpeed()`, `broadcastSetFeedMode()`
- Stream: `onDiscovery` for discovered devices

### lib/services/device_registry.dart
- Manages persistent storage via SharedPreferences
- Stores devices: UID ↔ IP ↔ friendly name
- Methods: `storeDevice()`, `getIpForUid()`, `getFriendlyName()`, `getDeviceUids()`, `updateDeviceIp()`, `removeDevice()`

### android/app/src/main/AndroidManifest.xml
- Added Bluetooth permissions (BLUETOOTH, BLUETOOTH_ADMIN, BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
- Added location permissions (ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION)
- Added network permissions (INTERNET, ACCESS_NETWORK_STATE)
- Declared BLE as required feature

### ios/Runner/Info.plist
- Added NSBluetoothCentralUsageDescription
- Added NSBluetoothPeripheralUsageDescription
- Added NSLocalNetworkUsageDescription
- Added NSBonjourServices

## Command Flow Diagrams

### BLE Control Flow
```
HomeScreen
    ↓ (tap Bluetooth)
ScanScreenBLE (scans for ReefFlow_*)
    ↓ (select device(s))
ControlScreenBLE (send 01/02/05 commands)
    ├─→ (optional) WiFiProvisionScreen (10/11 commands)
    └─→ (back) HomeScreen
```

### UDP Control Flow
```
HomeScreen
    ↓ (tap Wi-Fi)
DiscoveryScreenUDP (listens for UID:*,IP:* broadcasts)
    ↓ (select device(s))
ControlScreenUDP (send 01/02/05 commands to port 8888)
    └─→ (back) HomeScreen
```

## State Management

- **Per-screen**: StatefulWidget with setState() for UI updates
- **BLE connections**: Map of deviceId → ReefFlowBleClient
- **UDP discoveries**: Map of uid → UdpDevice
- **Selection state**: Map of deviceId/uid → isSelected boolean
- **Persistent**: DeviceRegistry with SharedPreferences backend

## Communication Protocols

### BLE
- Scan with device name prefix filter
- Connect → Discover services
- Write to characteristic (command)
- Read from characteristic (UID)
- Listen to notify (responses)

### UDP
- Bind socket to 0.0.0.0:8888
- Listen for incoming datagrams
- Send datagrams to IP:8888
- Parse ASCII messages

## Error Handling

- **BLE**: Try-catch on connect/write/read with user-facing SnackBar
- **UDP**: Silent catches with fallback logic
- **Permissions**: Runtime check at app startup
- **Wi-Fi provisioning**: Retry allowed on failure
- **Subnet check**: Warning dialog, not blocking

## Testing Recommendations

1. **Unit Tests**: Validate command formatting
2. **Integration Tests**: Connect to real/mock devices
3. **Manual Testing**:
   - BLE scan with multiple devices nearby
   - Multi-device connect/control
   - Wi-Fi provisioning flow
   - UDP discovery with multiple devices
   - Subnet mismatch scenarios

## Performance Considerations

- Stream subscriptions cancelled in dispose to prevent memory leaks
- Scan stopped before connecting to prevent BLE conflicts
- UDP socket reused for all sends (single bind)
- Device registry cached in memory after initial load
- UI updates debounced with setState throttling on sliders

## Security Notes

- No password storage (Wi-Fi password only used for join command)
- Device IP stored locally only
- UDP broadcast on local network (no internet)
- BLE connection encrypted by platform (handled by framework)
- No authentication needed for local network control (assumption: trusted LAN)
