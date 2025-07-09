import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amman_tms_mobile/core/api/api_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  String? _sessionId;
  static const String _sessionIdKey = 'session_id';
  static const String _userProfileKey = 'user_profile';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';

  String? get sessionId => _sessionId;
  String? _username;
  String? _password;

  String? get username => _username;
  String? get password => _password;

  // Get user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Save user ID
  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_userProfileKey);
    if (profileJson != null) {
      return jsonDecode(profileJson) as Map<String, dynamic>;
    }
    return null;
  }

  // Save user profile data
  Future<void> _saveUserProfile(Map<String, dynamic> profileData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(profileData));
  }

  // Initialize session from SharedPreferences
  Future<void> initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString(_sessionIdKey);
    _username = prefs.getString(_usernameKey);
    _password = prefs.getString(_passwordKey);
  }

  // Save session to SharedPreferences
  Future<void> _saveSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
    _sessionId = sessionId;
  }

  // Clear session and user data from SharedPreferences
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
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    // Step 1: Authenticate and get session ID
    final Uri authUri = Uri.parse('${ApiConfig.connectionEndpoint}');

    try {
      final http.Response authResponse = await http.post(
        authUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "params": {
            "db": "odoo17_copy_experiment",
            "login": username,
            "password": password,
          },
        }),
      );

      if (authResponse.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Authentication failed. Status: ${authResponse.statusCode}',
        };
      }

      // Extract session ID from cookies
      final cookies = authResponse.headers['set-cookie'];
      if (cookies != null) {
        final extractedSessionId = RegExp(
          r'session_id=([^;]+)',
        ).firstMatch(cookies)?.group(1);

        if (extractedSessionId != null) {
          await _saveSession(extractedSessionId);
          print('Session ID: $_sessionId');
        }
      }

      if (_sessionId == null) {
        return {'success': false, 'message': 'Failed to get session ID'};
      }

      // Step 2: Hit the main login API with session ID
      final Uri loginUri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}',
      );

      print("Login URL: $loginUri");

      final loginHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cookie': 'session_id=$_sessionId',
      };

      final body = jsonEncode({"login": username, "password": password});

      final http.Response response = await http.post(
        loginUri,
        headers: loginHeaders,
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          // Save username and password
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_usernameKey, username);
          await prefs.setString(_passwordKey, password);
          _username = username;
          _password = password;

          // Re-authenticate to ensure session ID is fresh
          final Uri authUri = Uri.parse('${ApiConfig.connectionEndpoint}');
          final http.Response authResponse = await http.post(
            authUri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              "jsonrpc": "2.0",
              "params": {
                "db": "odoo17_copy_experiment",
                "login": username,
                "password": password,
              },
            }),
          );

          if (authResponse.statusCode == 200) {
            final cookies = authResponse.headers['set-cookie'];
            if (cookies != null) {
              final extractedSessionId = RegExp(
                r'session_id=([^;]+)',
              ).firstMatch(cookies)?.group(1);

              if (extractedSessionId != null) {
                await _saveSession(extractedSessionId);
                print('Session ID refreshed: $_sessionId');
              }
            }
          }

          // Send FCM token to server
          try {
            final fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) {
              final fcmResponse = await http.put(
                Uri.parse('${ApiConfig.baseUrl}/user/fcm_token'),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'Cookie': 'session_id=$_sessionId',
                },
                body: jsonEncode({'fcm_token': fcmToken}),
              );

              if (fcmResponse.statusCode != 200) {
                print('Failed to send FCM token: ${fcmResponse.statusCode}');
              }
            }
          } catch (e) {
            print('Error sending FCM token: $e');
          }

          final String? jobTitle =
              responseData['data']['employee']?['job_title'];
          String userRole = 'unknown';
          if (jobTitle != null) {
            if (jobTitle.toLowerCase().contains('driver')) {
              userRole = 'driver';
            } else if (jobTitle.toLowerCase().contains('supervisor') ||
                jobTitle.toLowerCase().contains('system analyst')) {
              userRole = 'supervisor';
            } else if (jobTitle.toLowerCase().contains('passenger')) {
              userRole = 'passenger';
            }
          }

          // Save user profile data and ID
          if (responseData['data'] != null) {
            await _saveUserProfile(responseData['data']);
            if (responseData['data']['uid'] != null) {
              await _saveUserId(responseData['data']['uid'].toString());
            }
          }

          return {'success': true, 'userRole': userRole};
        } else {
          return {
            'success': false,
            'message':
                responseData['message'] ?? 'Login failed. Please try again.',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error during login: $e'};
    }
  }
}
