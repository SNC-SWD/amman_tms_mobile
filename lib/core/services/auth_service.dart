import 'dart:async';
import 'dart:convert';
import 'package:amman_tms_mobile/core/api/api_config.dart';

import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Kunci untuk SharedPreferences
  static const String _sessionIdKey = 'session_id';
  static const String _userProfileKey = 'user_profile';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';

  // Variabel state internal
  String? _sessionId;
  String? _username;
  String? _password;

  // Getter publik
  String? get sessionId => _sessionId;
  String? get username => _username;
  String? get password => _password;

  /// Menginisialisasi service dengan memuat data sesi dari SharedPreferences.
  Future<void> initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString(_sessionIdKey);
    _username = prefs.getString(_usernameKey);
    _password = prefs.getString(_passwordKey);
    print(
      '🔑 [AuthService] Session initialized. Session ID ${(_sessionId != null ? "found" : "not found")}.',
    );
  }

  /// Melakukan proses login utama dengan mekanisme coba lagi (retry).
  ///
  /// Mencoba login hingga 3 kali. Jika gagal dengan status 404 (sesi tidak valid),
  /// ia akan mencoba re-autentikasi dan mencoba lagi.
  Future<Map<String, dynamic>> login(String username, String password) async {
    await initializeSession();
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          print(
            '🔄 [AuthService] Retrying... Attempt ${attempt + 1}/$maxRetries',
          );
          await Future.delayed(retryDelay);
        }

        var response = await _makeLoginRequest(username, password);

        // Kasus 1: Sukses (200 OK)
        if (response.statusCode == 200) {
          final result = await _processLoginResponse(
            response,
            username,
            password,
          );
          // Jika API mengonfirmasi login berhasil, kembalikan hasilnya.
          // Jika tidak (misal: kredensial salah), tidak perlu coba lagi.
          return result;
        }

        // Kasus 2: Sesi tidak valid (404 Not Found)
        if (response.statusCode == 404) {
          print(
            '⚠️ [AuthService] Session invalid (404). Attempting re-authentication...',
          );
          final reAuthSuccess = await _reauthenticate(username, password);

          if (reAuthSuccess) {
            print(
              '✅ [AuthService] Re-authentication successful. Continuing to next attempt.',
            );
            continue; // Lanjutkan ke iterasi berikutnya untuk mencoba login lagi
          } else {
            print('❌ [AuthService] Re-authentication failed. Aborting.');
            return {
              'success': false,
              'message':
                  'Authentication failed. Could not establish a new session.',
            };
          }
        }

        // Kasus 3: Error server lain yang tidak bisa dipulihkan
        print(
          '❌ [AuthService] Unrecoverable server error: ${response.statusCode}. Aborting.',
        );
        return {
          'success': false,
          'message':
              'Server error: ${response.statusCode}. Please try again later.',
        };
      } catch (e) {
        print(
          '❌ [AuthService] Network error during attempt ${attempt + 1}: $e',
        );
        // Jika ini adalah percobaan terakhir, kembalikan error.
        if (attempt == maxRetries - 1) {
          return {
            'success': false,
            'message':
                'Network error after multiple attempts. Please check your connection.',
          };
        }
        // Jika tidak, loop akan berlanjut ke percobaan berikutnya.
      }
    }

    // Jika loop selesai tanpa berhasil login
    print('❌ [AuthService] Login failed after $maxRetries attempts.');
    return {
      'success': false,
      'message': 'Login failed after multiple attempts. Please try again.',
    };
  }

  /// Melakukan re-autentikasi untuk mendapatkan session ID baru.
  Future<bool> _reauthenticate(String username, String password) async {
    try {
      final Uri authUri = Uri.parse(ApiConfig.connectionEndpoint);
      final response = await http.post(
        authUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "params": {
            "db":
                "odoo17_copy_experiment", // Ganti dengan nama DB Anda jika perlu
            "login": username,
            "password": password,
          },
        }),
      );

      if (response.statusCode == 200) {
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          final extractedSessionId = RegExp(
            r'session_id=([^;]+)',
          ).firstMatch(cookies)?.group(1);
          if (extractedSessionId != null) {
            await _saveSession(extractedSessionId);
            print('✅ [AuthService] New session ID obtained and saved.');
            return true;
          }
        }
      }
      print(
        '❌ [AuthService] Re-authentication failed. Status: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      print('❌ [AuthService] Re-authentication error: $e');
      return false;
    }
  }

  /// Membuat request HTTP POST ke endpoint login.
  Future<http.Response> _makeLoginRequest(
    String username,
    String password,
  ) async {
    final Uri loginUri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_sessionId != null) 'Cookie': 'session_id=$_sessionId',
    };
    final body = jsonEncode({"login": username, "password": password});

    print('📡 [AuthService] Making login request to $loginUri');
    return await http.post(loginUri, headers: headers, body: body);
  }

  /// Memproses respons dari endpoint login.
  Future<Map<String, dynamic>> _processLoginResponse(
    http.Response response,
    String username,
    String password,
  ) async {
    if (response.statusCode != 200) {
      print('❌ [AuthService] Login failed with status: ${response.statusCode}');
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    }

    final Map<String, dynamic> responseData = jsonDecode(response.body);
    if (responseData['status'] == true) {
      print('✅ [AuthService] Login successful for user: $username');
      // Simpan kredensial
      await _saveCredentials(username, password);

      // Simpan data profil dan ID pengguna
      final data = responseData['data'];
      if (data != null) {
        await _saveUserProfile(data);
        if (data['uid'] != null) {
          await _saveUserId(data['uid'].toString());
        }
      }

      final reAuthSuccess = await _reauthenticate(username, password);
      if (!reAuthSuccess) {
        print('❌ [AuthService] Re-authentication failed when send fcm token.');
        return {
          'success': false,
          'message':
              'Re-authentication failed when send fcm token. Please try again.',
        };
      }

      // Kirim token FCM di latar belakang (tanpa menunggu selesai)
      _sendFcmToken();

      // Tentukan peran pengguna
      final String userRole = _determineUserRole(responseData);

      return {'success': true, 'userRole': userRole};
    } else {
      print('❌ [AuthService] Login failed: ${responseData['message']}');
      return {
        'success': false,
        'message': responseData['message'] ?? 'Login failed. Please try again.',
      };
    }
  }

  /// Menentukan peran pengguna berdasarkan `job_title`.
  String _determineUserRole(Map<String, dynamic> responseData) {
    final String? jobTitle = responseData['data']?['employee']?['job_title']
        ?.toLowerCase();
    if (jobTitle == null) return 'passenger';

    if (jobTitle.contains('driver')) return 'driver';
    if (jobTitle.contains('supervisor') || jobTitle.contains('system analyst'))
      return 'supervisor';

    return 'passenger'; // Default role
  }

  /// Mengirimkan FCM token ke server.
  Future<void> _sendFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || _sessionId == null) {
        print(
          '⚠️ [AuthService] FCM token or Session ID is null. Cannot send token.',
        );
        return;
      }

      print('📲 [AuthService] Sending FCM token to server...');
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/user/fcm_token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$_sessionId',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        print('✅ [AuthService] FCM token sent successfully.');
      } else {
        print(
          '❌ [AuthService] Failed to send FCM token. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ [AuthService] Error sending FCM token: $e');
    }
  }

  /// Menghapus semua data sesi dan pengguna dari SharedPreferences.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
    await prefs.remove(_userProfileKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
    _sessionId = null;
    _username = null;
    _password = null;
    print('🗑️ [AuthService] All session and user data cleared.');
  }

  // --- Metode Helper untuk SharedPreferences ---

  Future<void> _saveSession(String sessionId) async {
    _sessionId = sessionId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
  }

  Future<void> _saveCredentials(String username, String password) async {
    _username = username;
    _password = password;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_userProfileKey);
    return profileJson != null
        ? jsonDecode(profileJson) as Map<String, dynamic>
        : null;
  }

  Future<void> _saveUserProfile(Map<String, dynamic> profileData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(profileData));
  }
}
