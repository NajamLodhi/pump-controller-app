import 'package:shared_preferences/shared_preferences.dart';

/// Stores known devices (UID ↔ IP) and persists to SharedPreferences
class DeviceRegistry {
  static const String _keyPrefix = 'reef_device_';
  static const String _keyDeviceList = 'reef_devices_list';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Store a device with its UID and last known IP
  Future<void> storeDevice(String uid, String ip, {String? friendlyName}) async {
    final devices = await getDeviceUids();
    if (!devices.contains(uid)) {
      devices.add(uid);
      await _prefs.setStringList(_keyDeviceList, devices);
    }
    await _prefs.setString('$_keyPrefix${uid}_ip', ip);
    if (friendlyName != null) {
      await _prefs.setString('$_keyPrefix${uid}_name', friendlyName);
    }
  }

  /// Get the last known IP for a UID
  Future<String?> getIpForUid(String uid) async {
    return _prefs.getString('$_keyPrefix${uid}_ip');
  }

  /// Get friendly name for a UID (if set)
  Future<String?> getFriendlyName(String uid) async {
    return _prefs.getString('$_keyPrefix${uid}_name');
  }

  /// Get all known device UIDs
  Future<List<String>> getDeviceUids() async {
    return _prefs.getStringList(_keyDeviceList) ?? [];
  }

  /// Get device display name (friendly name or UID)
  Future<String> getDeviceDisplayName(String uid) async {
    final friendlyName = await getFriendlyName(uid);
    return friendlyName ?? uid;
  }

  /// Remove a device from storage
  Future<void> removeDevice(String uid) async {
    final devices = await getDeviceUids();
    devices.remove(uid);
    await _prefs.setStringList(_keyDeviceList, devices);
    await _prefs.remove('$_keyPrefix${uid}_ip');
    await _prefs.remove('$_keyPrefix${uid}_name');
  }

  /// Update IP for existing device
  Future<void> updateDeviceIp(String uid, String newIp) async {
    final devices = await getDeviceUids();
    if (devices.contains(uid)) {
      await _prefs.setString('$_keyPrefix${uid}_ip', newIp);
    }
  }
}
