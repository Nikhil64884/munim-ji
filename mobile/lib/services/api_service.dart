import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'storage_service.dart';

// dart:io and path_provider are not available on Flutter Web.
// We import them only on non-web builds via a conditional import.
import 'file_helper_stub.dart'
    if (dart.library.io) 'file_helper_io.dart'
    if (dart.library.js_interop) 'file_helper_web.dart' as file_helper;

/// Backend: Munim Ji AI API v3.1.0 (FastAPI)
///
/// Base URL kaise badlein (code me nahi, build command me):
///   Android emulator : flutter run --dart-define=APP_API_BASE_URL=http://10.0.2.2:8000
///   Asli phone       : flutter run --dart-define=APP_API_BASE_URL=http://<laptop-IP>:8000
///   Production       : flutter build apk --dart-define=APP_API_BASE_URL=https://aapka-server.com
class ApiService {
  static String _baseUrl = () {
    const envUrl = String.fromEnvironment('APP_API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    // Default Live Cloud Server (Render)
    return 'https://munim-yvqh.onrender.com';
  }();

  static String get baseUrl => _baseUrl;

  static String normalizeUrl(String url) {
    var clean = url.trim();
    if (clean.isEmpty) return '';
    if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    return clean;
  }

  static void setBaseUrl(String url) {
    _baseUrl = normalizeUrl(url);
  }

  static Future<void> initBaseUrl() async {
    final saved = await StorageService.getServerUrl();
    if (saved != null && saved.isNotEmpty) {
      setBaseUrl(saved);
    }
  }

  static Future<bool> checkHealthAt(String url) async {
    try {
      final clean = normalizeUrl(url);
      if (clean.isEmpty) return false;
      final res = await http.get(Uri.parse('$clean/healthz')).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkHealth() async {
    return checkHealthAt(_baseUrl);
  }

  static String get apiUrl => '$baseUrl/api';
  static const Duration _timeout = Duration(seconds: 30);

  /// Session expire (401) hone par app is callback se Login screen par bhej sakta hai.
  static VoidCallback? onSessionExpired;
  static bool _expiring = false;

  static void resetExpiring() {
    _expiring = false;
  }

  // ---------------------------------------------------------------- helpers
  static Future<Map<String, String>> _headers({bool withAuth = true, bool json = true}) async {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (withAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  static String _clientMsgId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000000)}';

  static String? _detail(dynamic body) {
    if (body is Map && body['detail'] is String) return body['detail'] as String;
    return null;
  }

  static String _friendly(int code, dynamic body, bool auth) {
    switch (code) {
      case 401:
        return auth ? 'Session expire ho gaya, dobara login karein' : 'Galat OTP';
      case 409:
        return 'Ye message pehle hi ho chuka hai';
      case 429:
        return 'Bahut zyada koshish. Thodi der baad try karein';
      case 422:
        return 'Galat ya adhura data';
    }
    if (code >= 500) return _detail(body) ?? 'Server me dikkat hai';
    return _detail(body) ?? 'HTTP $code';
  }

  static Future<Map<String, dynamic>> _call(
    Future<http.Response> Function() request, {
    bool auth = true,
    Duration timeout = _timeout,
  }) async {
    try {
      final res = await request().timeout(timeout);
      dynamic body;
      try {
        body = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        body = null;
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': body};
      }
      if (res.statusCode == 401 && auth) {
        if (!_expiring) {
          _expiring = true;
          await StorageService.clearAll();
          onSessionExpired?.call();
        }
      }
      return {
        'success': false,
        'status': res.statusCode,
        'error': _friendly(res.statusCode, body, auth),
      };
    } on TimeoutException catch (e) {
      debugPrint('[ApiService] TimeoutException: $e');
      return {'success': false, 'error': 'Server jawab nahi de raha, dobara try karein'};
    } catch (e, st) {
      debugPrint('[ApiService] Exception: $e\n$st');
      return {'success': false, 'error': 'Server se connect nahi ho paya. Kripya internet check karein'};
    }
  }

  // ------------------------------------------------------------------- auth
  static Future<Map<String, dynamic>> sendOtp(String phone) => _call(
        () async => http.post(Uri.parse('$apiUrl/auth/send-otp'),
            headers: await _headers(withAuth: false), body: jsonEncode({'phone': phone})),
        auth: false,
      );

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final r = await _call(
      () async => http.post(Uri.parse('$apiUrl/auth/verify-otp'),
          headers: await _headers(withAuth: false),
          body: jsonEncode({'phone': phone, 'otp': otp})),
      auth: false,
    );
    if (r['success'] == true) {
      final token = (r['data'] as Map?)?['token'] as String?;
      if (token == null || token.isEmpty) {
        return {'success': false, 'error': 'Login token nahi mila'};
      }
      resetExpiring();
      await StorageService.saveToken(token);
      await StorageService.savePhone(phone);
    }
    return r;
  }

  // ------------------------------------------------------------ chat / voice
  /// Entry, balance, undo, HAAN/NAHI, naam-picker: sab yahi se hota hai.
  static Future<Map<String, dynamic>> chat(String message) => _call(
        () async => http.post(Uri.parse('$apiUrl/chat'),
            headers: await _headers(),
            body: jsonEncode({'message': message, 'client_msg_id': _clientMsgId()})),
      );

  /// Awaaz ki file bhejein. Jawab: {transcript, reply, media_url?}
  static Future<Map<String, dynamic>> voice(String filePath) => _call(
        () async {
          final req = http.MultipartRequest('POST', Uri.parse('$apiUrl/voice'))
            ..headers.addAll(await _headers(json: false))
            ..files.add(await http.MultipartFile.fromPath('file', filePath));
          return http.Response.fromStream(await req.send());
        },
        timeout: const Duration(seconds: 90),
      );

  // --------------------------------------------------------------- customers
  static Future<Map<String, dynamic>> getCustomers() => _call(
      () async => http.get(Uri.parse('$apiUrl/customers'), headers: await _headers()));

  static Future<Map<String, dynamic>> getLedger(int customerId) => _call(() async =>
      http.get(Uri.parse('$apiUrl/customers/$customerId/ledger'), headers: await _headers()));

  static Future<Map<String, dynamic>> addCustomer(String name, String phone) => _call(
        () async => http.post(Uri.parse('$apiUrl/customers'),
            headers: await _headers(),
            body: jsonEncode({'name': name, 'phone': phone})),
      );

  static Future<Map<String, dynamic>> mergeCustomers(int fromId, int intoId) => _call(
      () async => http.post(Uri.parse('$apiUrl/customers/merge'),
          headers: await _headers(), body: jsonEncode({'from_id': fromId, 'into_id': intoId})));

  // ------------------------------------------------------------ transactions
  /// Backend ko transaction add karta hai via chat endpoint.
  /// type: 'jama' | 'udhaar' | 'cash'
  static Future<Map<String, dynamic>> addTransaction({
    required String type,
    required int amountRupees,
    String? customerName,
    String? note,
  }) {
    final parts = <String>[];
    if (customerName != null && customerName.isNotEmpty) parts.add(customerName);
    parts.add('$amountRupees');
    parts.add(type);
    if (note != null && note.isNotEmpty) parts.add(note);
    return chat(parts.join(' '));
  }

  /// type: 'Debit' (udhaar) | 'Credit' (jama) | 'CashSale'. Amount paise me.
  static Future<Map<String, dynamic>> patchTransaction(int id,
      {int? amountPaise, String? itemDesc, String? type}) {
    final body = <String, dynamic>{
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (itemDesc != null) 'item_desc': itemDesc,
      if (type != null) 'transaction_type': type,
    };
    return _call(() async => http.patch(Uri.parse('$apiUrl/transactions/$id'),
        headers: await _headers(), body: jsonEncode(body)));
  }

  static Future<Map<String, dynamic>> deleteTransaction(int id) => _call(() async =>
      http.delete(Uri.parse('$apiUrl/transactions/$id'), headers: await _headers()));

  // ------------------------------------------------------- summary / reports
  /// period: today | yesterday | week | month
  static Future<Map<String, dynamic>> getSummary(String period) => _call(() async =>
      http.get(
        Uri.parse('$apiUrl/summary').replace(queryParameters: {'period': period}),
        headers: await _headers(),
      ));

  static Future<Map<String, dynamic>> getAudit({int limit = 100}) => _call(() async =>
      http.get(Uri.parse('$apiUrl/audit?limit=$limit'), headers: await _headers()));

  /// Excel banwa kar phone me save karta hai. Jawab: {success, path/url, filename}
  static Future<Map<String, dynamic>> exportExcel() async {
    final r = await _call(
        () async => http.get(Uri.parse('$apiUrl/export'), headers: await _headers()));
    if (r['success'] != true) return r;
    final url = (r['data'] as Map?)?['url'] as String?;
    if (url == null) return {'success': false, 'error': 'Export file nahi bani'};
    return downloadMedia(url);
  }

  static String _safeFileName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  static Future<Map<String, dynamic>> downloadMedia(String mediaUrl) async {
    if (baseUrl.isEmpty) {
      return {'success': false, 'error': 'Server set nahi hai'};
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$mediaUrl'), headers: await _headers(json: false))
          .timeout(_timeout);
      if (res.statusCode == 401) {
        if (!_expiring) {
          _expiring = true;
          await StorageService.clearAll();
          onSessionExpired?.call();
        }
        return {'success': false, 'error': 'Session expire ho gaya, dobara login karein'};
      }
      if (res.statusCode != 200) {
        return {'success': false, 'error': 'File download nahi hui (HTTP ${res.statusCode})'};
      }
      final name = _safeFileName(mediaUrl.split('/').last);
      final path = await file_helper.saveBytes(name, res.bodyBytes);
      return {'success': true, 'path': path, 'filename': name};
    } catch (_) {
      return {'success': false, 'error': 'Server se connect nahi ho paya'};
    }
  }

  static Future<void> deleteLocalFile(String path) => file_helper.deleteFile(path);

  // ----------------------------------------------------------------- account
  static Future<Map<String, dynamic>> deleteAccount() async {
    final r = await _call(
        () async => http.delete(Uri.parse('$apiUrl/account'), headers: await _headers()));
    if (r['success'] == true) {
      await StorageService.clearAll();
      await StorageService.clearShopData();
    }
    return r;
  }

  static Future<void> logout() async {
    resetExpiring();
    await StorageService.clearAll();
    await StorageService.clearShopData();
  }

  // ------------------------------------------------------------ money helpers
  /// Backend balance_paise > 0 matlab customer ko dena hai (baaki).
  static int totalBaakiPaise(List customers) {
    var total = 0;
    for (final c in customers) {
      if (c is! Map) continue;
      final bp = c['balance_paise'];
      if (bp is num && bp > 0) {
        total += bp.toInt();
      } else {
        final b = c['balance'];
        if (b is num && b > 0) {
          total += (b * 100).round();
        }
      }
    }
    return total;
  }

  static String formatRupees(int paise) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: paise % 100 == 0 ? 0 : 2,
      ).format(paise / 100);
}
