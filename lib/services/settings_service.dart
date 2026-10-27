import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferencesAsync _storage = SharedPreferencesAsync();
  static const String _settingsKey = 'app_user_settings';

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> init() async {
    final service = SettingsService();
    final settings = await service.getSettings();
    final themeStr = settings['themeMode'] ?? 'light';
    if (themeStr == 'dark') {
      themeNotifier.value = ThemeMode.dark;
    } else if (themeStr == 'system') {
      themeNotifier.value = ThemeMode.system;
    } else {
      themeNotifier.value = ThemeMode.light;
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    final json = await _storage.getString(_settingsKey);
    if (json == null) {
      return {
        'themeMode': 'light',
        'autoBackup': true,
        'backupFrequency': 'Diário',
        'birthdayReminders': true,
      };
    }
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _storage.setString(_settingsKey, jsonEncode(settings));
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeNotifier.value = mode;
    final settings = await getSettings();
    var str = 'light';
    if (mode == ThemeMode.dark) str = 'dark';
    if (mode == ThemeMode.system) str = 'system';
    settings['themeMode'] = str;
    await saveSettings(settings);
  }

  Future<void> setAutoBackup(bool enabled) async {
    final settings = await getSettings();
    settings['autoBackup'] = enabled;
    await saveSettings(settings);
  }

  Future<void> setBackupFrequency(String frequency) async {
    final settings = await getSettings();
    settings['backupFrequency'] = frequency;
    await saveSettings(settings);
  }

  Future<void> setBirthdayReminders(bool enabled) async {
    final settings = await getSettings();
    settings['birthdayReminders'] = enabled;
    await saveSettings(settings);
  }
}
