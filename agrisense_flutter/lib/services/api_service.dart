import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Cookie storage for session
  String? _sessionCookie;

  Future<void> _loadCookie() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('session_cookie');
  }

  Future<void> _saveCookie(String cookie) async {
    _sessionCookie = cookie;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_cookie', cookie);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      };

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      };

  void _extractCookie(http.Response response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final sessionCookie = rawCookie.split(';').first;
      _saveCookie(sessionCookie);
    }
  }

  // ─── AUTH ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    await _loadCookie();
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      _extractCookie(response);

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', email);
        await prefs.setString('username', data['username'] ?? '');
        await prefs.setString('user_type', data['user_type'] ?? 'farmer');
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid email or password'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Is Flask running on port 5000?'};
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password, String userType) async {
    await _loadCookie();
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: _jsonHeaders,
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'user_type': userType,
        }),
      ).timeout(const Duration(seconds: 15));

      _extractCookie(response);

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', email);
        await prefs.setString('username', data['username'] ?? username);
        await prefs.setString('user_type', data['user_type'] ?? userType);
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Is Flask running on port 5000?'};
    }
  }

  Future<void> logout() async {
    await _loadCookie();
    try {
      await http.post(Uri.parse(ApiConfig.logout), headers: _jsonHeaders);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _sessionCookie = null;
  }

  // ─── PRICE DEMAND ─────────────────────────────────────────
  Future<Map<String, dynamic>> predictPriceDemand(Map<String, dynamic> data) async {
    await _loadCookie();
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.priceDemand),
        headers: _headers,
        body: data.map((k, v) => MapEntry(k, v.toString())),
      ).timeout(const Duration(seconds: 30));
      _extractCookie(response);
      return _parseHtmlResponse(response.body, 'price_demand');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── MARKET RANKING ───────────────────────────────────────
  Future<Map<String, dynamic>> predictMarketRanking(Map<String, dynamic> data) async {
    await _loadCookie();
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.marketRanking),
        headers: _headers,
        body: data.map((k, v) => MapEntry(k, v.toString())),
      ).timeout(const Duration(seconds: 30));
      _extractCookie(response);
      return {'success': true, 'html': response.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── CULTIVATION TARGETING ────────────────────────────────
  Future<Map<String, dynamic>> predictCultivation(Map<String, dynamic> data) async {
    await _loadCookie();
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.cultivationTargeting),
        headers: _headers,
        body: data.map((k, v) => MapEntry(k, v.toString())),
      ).timeout(const Duration(seconds: 30));
      _extractCookie(response);
      return {'success': true, 'html': response.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── YIELD QUALITY (works on Web + Android) ──────────────
  Future<Map<String, dynamic>> predictYieldQualityXFile(
      List<XFile> images, double bestUnitPrice) async {
    await _loadCookie();
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.yieldQuality),
      );
      if (_sessionCookie != null) {
        request.headers['Cookie'] = _sessionCookie!;
      }
      request.fields['best_unit_price'] = bestUnitPrice.toString();
      for (final image in images) {
        final bytes = await image.readAsBytes();
        final filename = image.name;
        request.files.add(http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: filename,
        ));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      _extractCookie(response);
      return {'success': true, 'html': response.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── PROFITABLE STRATEGY ──────────────────────────────────
  Future<Map<String, dynamic>> predictProfitableStrategy(Map<String, dynamic> data) async {
    await _loadCookie();
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.profitableStrategy),
        headers: _headers,
        body: data.map((k, v) => MapEntry(k, v.toString())),
      ).timeout(const Duration(seconds: 30));
      _extractCookie(response);
      return {'success': true, 'html': response.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── HISTORY ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getHistory() async {
    await _loadCookie();
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.history),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      _extractCookie(response);
      return {'success': true, 'html': response.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── API HELPERS ──────────────────────────────────────────
  Future<List<String>> getDistricts(String province) async {
    await _loadCookie();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getDistricts}/$province'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['districts'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  Future<List<String>> getItems(String category) async {
    await _loadCookie();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getItems}/$category'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['items'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  Map<String, dynamic> _parseHtmlResponse(String html, String type) {
    return {'success': true, 'html': html};
  }
}
