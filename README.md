# ReefFlow WaveMaker Mobile App

Flutter app for controlling ReefFlow wave maker devices over:
- Bluetooth Low Energy (BLE)
- Wi-Fi / UDP (local network)

## Features
- Discover ReefFlow devices over BLE
- Connect to one or more BLE devices and control them together
- Set wave mode (`Sine`, `Pulse`, `Constant`)
- Set speed (`0-100`)
- Trigger feed mode (`2 min`, `5 min`, `Cancel`)
- Provision device Wi-Fi from BLE (scan SSIDs, join network)
- Discover Wi-Fi devices via UDP broadcast
- Control one or more Wi-Fi devices together
- Store device UID/IP mapping in local storage

## Tech Stack
- Flutter (Dart)
- `flutter_blue_plus` for BLE
- `permission_handler` for runtime permissions
- `network_info_plus` for phone Wi-Fi/subnet checks
- `shared_preferences` for local device registry

## Project Structure
```text
lib/
  main.dart                         App entry, permission requests
  screens/
    home_screen.dart                Mode selection (BLE or Wi-Fi)
    ble/
      scan_screen_ble.dart          BLE discovery + connection
      control_screen_ble.dart       BLE control panel
      wifi_provision_screen.dart    Wi-Fi provisioning over BLE
    wifi/
      discovery_screen_udp.dart     UDP discovery
      control_screen_udp.dart       UDP control panel
  services/
    ble_client.dart                 BLE protocol client
    udp_client.dart                 UDP discovery + command sender
    device_registry.dart            SharedPreferences UID/IP storage
```

## Communication Protocol
The app sends plaintext commands used by ReefFlow firmware:
- `01 <mode>`: wave mode (`0=Sine`, `1=Pulse`, `2=Constant`)
- `05 <speed>`: speed (`0-100`)
- `02 <minutes>`: feed mode (`2`, `5`, `0` to cancel)
- `10 SCAN`: request Wi-Fi SSID scan over BLE
- `11 <ssid>,<password>`: request Wi-Fi join over BLE

Expected BLE notifications include:
- SSID scan lines in `SSID,RSSI` format
- Wi-Fi join status such as `CONNECTED <ip>` or `CONNECT_FAILED`

## Prerequisites
- Flutter SDK installed and available in PATH
- Android Studio / Xcode toolchain configured (depending on target platform)
- ReefFlow devices powered on and in range
- For UDP control: phone and devices on same Wi-Fi subnet

## Setup
```bash
flutter pub get
```

## Run
```bash
flutter run
```

## Build
Android APK:
```bash
flutter build apk --release
```

Android App Bundle:
```bash
flutter build appbundle --release
```

iOS (from macOS with Xcode configured):
```bash
flutter build ios --release
```

## How To Use
1. Launch app.
2. Choose one mode:
   - `Control via Bluetooth (BLE)`
   - `Control via Wi-Fi (Router)`

### BLE Flow
1. Scan and select ReefFlow devices.
2. Connect to one or more devices.
3. Open control screen and send wave/speed/feed commands.
4. Optional: open **Setup Wi-Fi** to provision network credentials.

### Wi-Fi / UDP Flow
1. Ensure devices are already connected to Wi-Fi.
2. Open UDP discovery and wait for device broadcasts (`UID:<uid>,IP:<ip>`).
3. Select one or more devices.
4. Control all selected devices together.

## Permissions
On startup, the app requests:
- Bluetooth scan/connect permissions
- Location permission (required for BLE scanning on many Android devices)

## Known Limitations
- BLE scan matching depends on advertised name/UUID heuristics.
- UDP mode is local-network only; no cloud/remote relay.
- No formal retry/backoff strategy for transient BLE/UDP send failures yet.

## Troubleshooting
- No BLE devices found:
  - Confirm Bluetooth is enabled.
  - Confirm permissions are granted.
  - Move closer to device and rescan.
- UDP devices not discovered:
  - Confirm device is on Wi-Fi.
  - Confirm phone and device are on same subnet.
  - Ensure local network permissions are allowed.
- Commands appear ignored:
  - Reconnect device and retry.
  - Verify firmware supports listed command protocol.

## Development Notes
- Default app entry: `lib/main.dart`
- Main home screen: `lib/screens/home_screen.dart`
- Core protocol code: `lib/services/ble_client.dart`, `lib/services/udp_client.dart`

## License
No license file is currently included.
Add a `LICENSE` file before publishing as open-source.
