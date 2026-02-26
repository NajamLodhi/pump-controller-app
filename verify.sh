#!/bin/bash
# ReefFlow WaveMaker App - Verification Script

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ReefFlow WaveMaker Flutter App - Verification            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "📦 Checking project structure..."
echo ""

# Check main.dart
if [ -f "lib/main.dart" ]; then
  echo "✓ lib/main.dart"
else
  echo "✗ lib/main.dart NOT FOUND"
fi

# Check screens
SCREENS=(
  "lib/screens/home_screen.dart"
  "lib/screens/ble/scan_screen_ble.dart"
  "lib/screens/ble/control_screen_ble.dart"
  "lib/screens/ble/wifi_provision_screen.dart"
  "lib/screens/wifi/discovery_screen_udp.dart"
  "lib/screens/wifi/control_screen_udp.dart"
)

echo ""
echo "UI Screens:"
for screen in "${SCREENS[@]}"; do
  if [ -f "$screen" ]; then
    echo "  ✓ $(basename $screen)"
  else
    echo "  ✗ $(basename $screen) NOT FOUND"
  fi
done

# Check services
SERVICES=(
  "lib/services/ble_client.dart"
  "lib/services/udp_client.dart"
  "lib/services/device_registry.dart"
)

echo ""
echo "Services:"
for service in "${SERVICES[@]}"; do
  if [ -f "$service" ]; then
    echo "  ✓ $(basename $service)"
  else
    echo "  ✗ $(basename $service) NOT FOUND"
  fi
done

# Check config files
echo ""
echo "Configuration Files:"
if [ -f "pubspec.yaml" ]; then
  echo "  ✓ pubspec.yaml"
else
  echo "  ✗ pubspec.yaml NOT FOUND"
fi

if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
  echo "  ✓ AndroidManifest.xml"
else
  echo "  ✗ AndroidManifest.xml NOT FOUND"
fi

if [ -f "ios/Runner/Info.plist" ]; then
  echo "  ✓ Info.plist"
else
  echo "  ✗ Info.plist NOT FOUND"
fi

# Check dependencies
echo ""
echo "Checking dependencies..."
if command -v flutter &> /dev/null; then
  echo "  ✓ Flutter $(flutter --version | head -1)"
else
  echo "  ✗ Flutter not found"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Verification Complete                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "To get started:"
echo "  1. flutter pub get"
echo "  2. flutter analyze"
echo "  3. flutter run"
echo ""
