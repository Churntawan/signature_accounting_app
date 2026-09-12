import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class SettingsService {
  static const String _storageKey = 'signature_accounting_app_config_v1';
  static AppConfig _config = AppConfig.defaults();
  static final ValueNotifier<AppConfig> configNotifier =
      ValueNotifier<AppConfig>(_config);

  static AppConfig get config => _config;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        _config = AppConfig.deserialize(savedJson);
        configNotifier.value = _config;
      }
    } catch (e) {
      debugPrint('SettingsService.init error: $e');
    }
  }

  static Future<bool> saveConfig(AppConfig newConfig) async {
    try {
      _config = newConfig;
      configNotifier.value = _config;
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_storageKey, newConfig.serialize());
    } catch (e) {
      debugPrint('SettingsService.saveConfig error: $e');
      return false;
    }
  }

  static Future<bool> resetToDefaults() async {
    try {
      _config = AppConfig.defaults();
      configNotifier.value = _config;
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('SettingsService.resetToDefaults error: $e');
      return false;
    }
  }
}
