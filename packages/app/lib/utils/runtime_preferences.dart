import 'package:shared_preferences/shared_preferences.dart';

class RuntimePreferences {
  RuntimePreferences._();

  static const String _mobileLocalHostingEnabledKey =
      'mobile_local_hosting_enabled';

  static Future<bool> isMobileLocalHostingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mobileLocalHostingEnabledKey) ?? false;
  }

  static Future<void> setMobileLocalHostingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mobileLocalHostingEnabledKey, enabled);
  }
}
