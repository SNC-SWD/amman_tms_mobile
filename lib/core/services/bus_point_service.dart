import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amman_tms_mobile/core/api/api_config.dart';
import 'package:amman_tms_mobile/core/services/auth_service.dart';

class BusPointService {
  final AuthService _authService;
  String? _sessionId;

  BusPointService({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    await _authService.initializeSession();
  }

  Future<String?> _getSessionId() async {
    await _authService.initializeSession();
    _sessionId = _authService.sessionId;
    print(
      '🔑 [BusPointService] Retrieved sessionId from storage: ${_sessionId != null ? 'Found' : 'Not found'}',
    );
    return _sessionId;
  }

  Future<bool> _reAuthenticate() async {
    try {
      print('🔄 [BusPointService] Attempting re-authentication...');
      final Uri authUri = Uri.parse('${ApiConfig.connectionEndpoint}');
      final response = await http.post(
        authUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "params": {
            "db": "odoo17_copy_experiment",
            "login": _authService.username,
            "password": _authService.password,
          },
        }),
      );

      print(
        '🔐 [BusPointService] Re-authentication response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          final newSessionId = RegExp(
            r'session_id=([^;]+)',
          ).firstMatch(cookies)?.group(1);
          if (newSessionId != null) {
            _sessionId = newSessionId;
            print(
              '✅ [BusPointService] Re-authentication successful, new sessionId obtained',
            );
            return true;
          }
        }
        print(
          '❌ [BusPointService] Re-authentication failed: No sessionId in cookies',
        );
      } else {
        print(
          '❌ [BusPointService] Re-authentication failed: Status ${response.statusCode}',
        );
      }
      return false;
    } catch (e) {
      print('❌ [BusPointService] Re-authentication error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getBusPoints() async {
    try {
      print('📍 [BusPointService] Fetching bus points');

      // Ensure session is valid before making API call
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        print(
          '❌ [BusPointService] Re-authentication failed, cannot proceed with request',
        );
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }
      String? sessionId = _sessionId;

      final Uri uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.getBusPoints}',
      );

      print('🌐 [BusPointService] Making request to: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$_sessionId',
        },
      );

      print('📡 [BusPointService] Response status: ${response.statusCode}');

      if (response.statusCode == 404) {
        print(
          '⚠️ [BusPointService] Not Found (404), attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          print(
            '🔄 [BusPointService] Re-authentication successful, retrying request',
          );
          final retryResponse = await http.get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Cookie': 'session_id=$_sessionId',
            },
          );

          print(
            '📡 [BusPointService] Retry response status: ${retryResponse.statusCode}',
          );

          if (retryResponse.statusCode == 200) {
            print('✅ [BusPointService] Retry successful, returning data');
            return jsonDecode(retryResponse.body);
          }
        }
        print('❌ [BusPointService] Retry failed, returning error');
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      if (response.statusCode == 200) {
        print('✅ [BusPointService] Request successful, returning data');
        return jsonDecode(response.body);
      } else {
        print(
          '❌ [BusPointService] Request failed with status: ${response.statusCode}',
        );
        return {
          'status': false,
          'message':
              'Failed to fetch bus points. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [BusPointService] Network error: $e');
      return {'status': false, 'message': 'Network error: $e'};
    }
  }
}
