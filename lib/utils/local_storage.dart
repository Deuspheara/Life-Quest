import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_quest/utils/error_handler.dart';

class LocalStorage {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Regular storage for non-sensitive data
  static Future<bool> saveData(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      } else {
        // For complex objects, serialize to JSON
        await prefs.setString(key, jsonEncode(value));
      }

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to save data to local storage', e);
      return false;
    }
  }

  static Future<dynamic> getData(String key, {dynamic defaultValue}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(key)) {
        return defaultValue;
      }

      return prefs.get(key);
    } catch (e) {
      ErrorHandler.logError('Failed to get data from local storage', e);
      return defaultValue;
    }
  }

  static Future<bool> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey(key)) {
        await prefs.remove(key);
        return true;
      }

      return false;
    } catch (e) {
      ErrorHandler.logError('Failed to remove data from local storage', e);
      return false;
    }
  }

  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to clear local storage', e);
      return false;
    }
  }

  // Secure storage for sensitive data
  static Future<bool> saveSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to save data to secure storage', e);
      return false;
    }
  }

  static Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      ErrorHandler.logError('Failed to get data from secure storage', e);
      return null;
    }
  }

  static Future<bool> removeSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to remove data from secure storage', e);
      return false;
    }
  }

  static Future<bool> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to clear secure storage', e);
      return false;
    }
  }
}