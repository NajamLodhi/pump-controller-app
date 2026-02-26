# Quick Start Guide - ReefFlow WaveMaker Mobile App

## Prerequisites

- **Flutter**: 3.10.1 or later
- **Dart**: 3.10 or later
- **iOS** (optional): Xcode 14+, CocoaPods
- **Android** (optional): Android Studio, API 21+
- **Physical Device or Emulator** with Bluetooth capability

## Installation

### 1. Clone/Setup the Project
```bash
cd /path/to/reefflow_mobile_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Code Analysis
```bash
flutter analyze
```

All should pass with no errors (only info/warnings about style).

## Running the App

### On Physical Device

**iOS**:
```bash
flutter run -d <device_id>
# First connect your iPhone via USB and get device ID
# or flutter run -d "iPhone (14 Pro)"
```

**Android**:
```bash
flutter run -d <device_id>
# Enable USB debugging on your device
# adb devices to list connected devices
```

### On Emulator

**iOS Simulator**:
```bash
open -a Simulator
flutter run
```

**Android Emulator**:
```bash
flutter emulators --launch Pixel_4_API_30
flutter run
```

## First Launch Permissions

The app will prompt for:
1. **Bluetooth permissions** (Android 12+)
   - BLUETOOTH_SCAN
   - BLUETOOTH_CONNECT
2. **Location permission** (required for BLE scan on Android 6+)
   - ACCESS_FINE_LOCATION

**Grant all permissions** for full functionality.

## Using the App

### BLE Control (Device Not on Wi-Fi)

1. **Start BLE Flow**
   - Tap "Control via Bluetooth (BLE)" on home screen
   
2. **Scan for Devices**
   - ScanScreenBLE opens and automatically scans
   - Wait ~10 seconds for nearby `ReefFlow_*` devices to appear
   - Device appears as: `ReefFlow_<UID>` (MAC address shown)
   
3. **Connect to Devices**
   - Tap device row to connect (shows spinner while connecting)
   - Tap again to disconnect
   - Select one or multiple devices
   
4. **Control Devices**
   - Tap "Control Selected Devices" (FAB at bottom)
   - ControlScreenBLE shows device list and controls
   - Adjust:
     - **Wave Mode**: Sine/Pulse/Constant
     - **Speed**: Slider 0-100%
     - **Feed**: 2 min / 5 min / Cancel buttons
   - Commands broadcast to all selected devices in real-time
   
5. (Optional) **Setup Wi-Fi**
   - Tap "Setup Wi-Fi (Optional)" button
   - WiFiProvisionScreen opens
   - Tap "Scan Wi-Fi Networks"
   - Wait for SSID list to appear
   - Select SSID from dropdown (or type manually)
   - Enter Wi-Fi password
   - Tap "Connect to Wi-Fi"
   - Success dialog shows device IP

### UDP Control (Device on Wi-Fi)

1. **Start UDP Flow**
   - Make sure ReefFlow device is already connected to your Wi-Fi
   - Tap "Control via Wi-Fi (Router)" on home screen
   
2. **Wait for Discovery**
   - DiscoveryScreenUDP opens and starts listening for UDP broadcasts
   - Device broadcasts every ~5 seconds: `UID:<uid>,IP:<ip>`
   - List updates live as devices are discovered
   - May take up to 10 seconds to appear
   
3. **Select Devices**
   - Check boxes next to device(s) you want to control
   - Checkbox next to UID toggles selection
   
4. **Control Devices**
   - Tap "Control Selected Devices" (FAB at bottom)
   - ControlScreenUDP opens
   - Shows:
     - **Phone IP**: Your phone's Wi-Fi IP address
     - **Device IPs**: Selected device IP(s)
     - **Subnet Warning**: Alert if not on same subnet as devices
   - Same controls as BLE (Wave/Speed/Feed)
   - Commands send to all selected device IPs on port 8888

## Development Tips

### Enable Hot Reload
```bash
flutter run
# Press 'r' in terminal to hot reload code changes
# Press 'R' to hot restart (resets app state)
```

### View Logs
```bash
flutter logs
# Shows real-time device logs
```

### Verbose Output
```bash
flutter run -v
# Shows detailed build/run information
```

### Debug Mode
- Android Studio: Run → Debug
- VS Code: Run → Start Debugging

## Troubleshooting

### "No ReefFlow devices found"

**BLE Issue:**
1. Ensure device is powered on and advertising
2. Check if device name starts with `ReefFlow_`
3. Try manual rescan (tap "Scan Again" button)
4. Verify Bluetooth is enabled on phone
5. On Android: Grant location permission (required for BLE scan)

**UDP Issue:**
1. Verify device is connected to Wi-Fi router
2. Ensure phone is on same Wi-Fi network as device
3. Ensure UDP port 8888 is not blocked
4. Check if router has multicast enabled (for discovery)
5. Try restarting device and app

### Connection Fails

**BLE:**
- Try connecting again (tap device row)
- Restart app
- Restart device

**UDP:**
- Check subnet (warning dialog shows subnet mismatch)
- Verify both on same Wi-Fi network
- Try connecting device to Wi-Fi again

### Permissions Not Granted

On Android:
```bash
adb shell pm grant com.example.reefflow_mobile_app \
  android.permission.BLUETOOTH_SCAN
adb shell pm grant com.example.reefflow_mobile_app \
  android.permission.BLUETOOTH_CONNECT
adb shell pm grant com.example.reefflow_mobile_app \
  android.permission.ACCESS_FINE_LOCATION
```

### App Crashes

1. Check logs: `flutter logs`
2. Verify device is connected: `adb devices` or `instruments -s devices`
3. Rebuild: `flutter clean && flutter pub get && flutter run`
4. Check analysis: `flutter analyze`

## Building for Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

### Android App Bundle
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS Archive
```bash
flutter build ios --release
# Open ios/Runner.xcworkspace in Xcode
# Use Xcode to create archive and upload to App Store
```

## Key Shortcuts

| Action | BLE | UDP |
|--------|-----|-----|
| Connect device | Tap row | Checkbox |
| Change wave | Button tap | Button tap |
| Change speed | Slider | Slider |
| Feed 5 min | Button tap | Button tap |
| Setup Wi-Fi | Orange button | N/A |
| Back | Press back | Press back |

## Support

### Common Commands

Check device is accessible (assuming device IP is 192.168.1.100):
```bash
# Ping device
ping 192.168.1.100

# Check UDP port
nc -u 192.168.1.100 8888
```

### Logs Location
- iOS: Xcode → Device/Simulator → Logs
- Android: `adb logcat` or Android Studio Logcat

## Next Steps

1. **Test with physical ReefFlow device**
2. **Verify BLE commands are received** (check device firmware logs)
3. **Verify UDP commands are received** (check device firmware logs)
4. **Test multi-device scenarios** (3+ devices simultaneously)
5. **Test on different phones** (iOS and Android)
6. **Test edge cases** (network loss, device disconnect, rapid switching)

## Documentation Files

- `IMPLEMENTATION.md` – Detailed protocol and architecture
- `PROJECT_STRUCTURE.md` – Code layout and design patterns
- `pubspec.yaml` – Dependencies and build configuration
- Source files have inline comments explaining key logic

---

**Happy controlling! 🌊**
