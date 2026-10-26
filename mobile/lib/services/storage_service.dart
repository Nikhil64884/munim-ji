import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'jwt_token';
  static const String _keyPhone = 'user_phone';
  static const String _keyShopName = 'shop_name';
  static const String _keyUpiId = 'shop_upi_id';
  static const String _keyTheme = 'app_theme_mode';
  static const String _keyLang = 'app_language';
  static const String _keyServerUrl = 'custom_server_url';
  static const String _keyFirstRun = 'app_first_run_done';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// iOS Keychain persists across app uninstalls. Clear on clean first launch.
  static Future<void> initFirstRunCheck() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyFirstRun) != true) {
      try {
        await _secureStorage.deleteAll();
      } catch (_) {}
      await prefs.setBool(_keyFirstRun, true);
    }
  }

  // ---------- Token (Stored Strictly in Secure Storage) ----------
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _keyToken);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _keyToken);
    } catch (_) {}
  }

  // ---------- Phone ----------
  static Future<void> savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  // ---------- Shop Name ----------
  static Future<void> saveShopName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyShopName, name);
  }

  static Future<String?> getShopName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyShopName);
  }

  // ---------- Shop UPI ID ----------
  static Future<void> saveUpiId(String upiId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUpiId, upiId);
  }

  static Future<String?> getUpiId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUpiId);
  }

  // ---------- Theme Mode ----------
  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, mode);
  }

  static Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTheme);
  }

  // ---------- Language ----------
  static Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, lang);
  }

  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLang);
  }

  // ---------- Server URL ----------
  static Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url.trim());
  }

  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }

  // ---------- Clear All ----------
  static Future<void> clearAll() async {
    await clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhone);
  }

  // ---------- Clear Shop Data ----------
  static Future<void> clearShopData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyShopName);
    await prefs.remove(_keyUpiId);
  }

  // ---------- Logout ----------
  static Future<void> logout() async {
    await clearAll();
    await clearShopData();
  }

  // ---------- Check Login ----------
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}