import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amman_tms_mobile/core/api/api_config.dart';
import 'package:amman_tms_mobile/core/services/auth_service.dart';

class FleetService {
  final AuthService _authService;
  String? _sessionId;

  FleetService({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<String?> _getSessionId() async {
    // Get sessionId from AuthService's local storage
    await _authService.initializeSession();
    _sessionId = _authService.sessionId;
    print(
      '🔑 [FleetService] Retrieved sessionId from storage: ${_sessionId != null ? 'Found' : 'Not found'}',
    );
    return _sessionId;
  }

  Future<bool> _reAuthenticate() async {
    try {
      print('🔄 [FleetService] Attempting re-authentication...');
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
        '🔐 [FleetService] Re-authentication response status: ${response.statusCode}',
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
              '✅ [FleetService] Re-authentication successful, new sessionId obtained',
            );
            // The sessionId will be automatically saved by AuthService during login
            return true;
          }
        }
        print(
          '❌ [FleetService] Re-authentication failed: No sessionId in cookies',
        );
      } else {
        print(
          '❌ [FleetService] Re-authentication failed: Status ${response.statusCode}',
        );
      }
      return false;
    } catch (e) {
      print('❌ [FleetService] Re-authentication error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getFleets({
    String? fleetType,
    String? fleetName,
    String? driverName,
    String? statusName,
  }) async {
    try {
      print(
        '🚌 [FleetService] Fetching fleets with params: type=$fleetType, name=$fleetName, driver=$driverName, status=$statusName',
      );

      // Ensure session is valid before making API call
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        print(
          '❌ [FleetService] Re-authentication failed, cannot proceed with request',
        );
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }
      String? sessionId = _sessionId;

      final Uri uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getFleets}')
          .replace(
            queryParameters: {
              if (fleetType != null) 'fleet_type': fleetType,
              if (fleetName != null) 'fleet_name': fleetName,
              if (driverName != null) 'driver_name': driverName,
              if (statusName != null) 'status_name': statusName,
            },
          );

      print('🌐 [FleetService] Making request to: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$sessionId',
        },
      );

      print('📡 [FleetService] Response status: ${response.statusCode}');

      // If unauthorized, try to re-authenticate once
      if (response.statusCode == 404) {
        print(
          '⚠️ [FleetService] Not Found (404), attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          print(
            '🔄 [FleetService] Re-authentication successful, retrying request',
          );
          // Retry the request with new sessionId
          final retryResponse = await http.get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Cookie': 'session_id=$_sessionId',
            },
          );

          print(
            '📡 [FleetService] Retry response status: ${retryResponse.statusCode}',
          );

          if (retryResponse.statusCode == 200) {
            print('✅ [FleetService] Retry successful, returning data');
            return jsonDecode(retryResponse.body);
          }
        }
        print('❌ [FleetService] Retry failed, returning error');
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      if (response.statusCode == 200) {
        print('✅ [FleetService] Request successful, returning data');
        return jsonDecode(response.body);
      } else {
        print(
          '❌ [FleetService] Request failed with status: ${response.statusCode}',
        );
        return {
          'status': false,
          'message': 'Failed to fetch fleets. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [FleetService] Network error: $e');
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyAssignedBus(String driverId) async {
    try {
      print('🚌 [FleetService] Fetching assigned bus for driver: $driverId');

      // Ensure session is valid before making API call
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        print(
          '❌ [FleetService] Re-authentication failed, cannot proceed with request',
        );
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }
      String? sessionId = _sessionId;

      final Uri uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.getFleets}',
      ).replace(queryParameters: {'driver_id': driverId});

      print('🌐 [FleetService] Making request to: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$sessionId',
        },
      );

      print('📡 [FleetService] Response status: ${response.statusCode}');

      // If unauthorized, try to re-authenticate once
      if (response.statusCode == 404) {
        print(
          '⚠️ [FleetService] Not Found (404), attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          print(
            '🔄 [FleetService] Re-authentication successful, retrying request',
          );
          // Retry the request with new sessionId
          final retryResponse = await http.get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Cookie': 'session_id=$_sessionId',
            },
          );

          print(
            '📡 [FleetService] Retry response status: ${retryResponse.statusCode}',
          );

          if (retryResponse.statusCode == 200) {
            print('✅ [FleetService] Retry successful, returning data');
            return jsonDecode(retryResponse.body);
          }
        }
        print('❌ [FleetService] Retry failed, returning error');
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      if (response.statusCode == 200) {
        print('✅ [FleetService] Request successful, returning data');
        return jsonDecode(response.body);
      } else {
        print(
          '❌ [FleetService] Request failed with status: ${response.statusCode}',
        );
        return {
          'status': false,
          'message':
              'Failed to fetch assigned bus. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [FleetService] Network error: $e');
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateVehicleStatus({
    required int busId,
    required int statusSeq,
  }) async {
    try {
      print(
        '🚦 [FleetService] Updating vehicle status for busId: $busId to statusSeq: $statusSeq',
      );
      // Ensure session is valid before making API call
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        print(
          '❌ [FleetService] Re-authentication failed, cannot proceed with request',
        );
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }
      String? sessionId = _sessionId;
      final Uri uri = Uri.parse('${ApiConfig.baseUrl}/vehicle/$busId/status');
      print('🌐 [FleetService] Making PATCH request to: ${uri.toString()}');
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$sessionId',
        },
        body: jsonEncode({'status_seq': statusSeq}),
      );
      print('📡 [FleetService] Response status: ${response.statusCode}');
      if (response.statusCode == 404) {
        print(
          '⚠️ [FleetService] Not Found (404), attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          print(
            '🔄 [FleetService] Re-authentication successful, retrying request',
          );
          final retryResponse = await http.patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Cookie': 'session_id=$_sessionId',
            },
            body: jsonEncode({'status_seq': statusSeq}),
          );
          print(
            '📡 [FleetService] Retry response status: ${retryResponse.statusCode}',
          );
          if (retryResponse.statusCode == 200) {
            print('✅ [FleetService] Retry successful, returning data');
            final data = jsonDecode(retryResponse.body);
            if (data['result'] != null) {
              return {
                'status': data['result']['status'] == true,
                'message': data['result']['message'] ?? '',
                'data': data['result']['data'],
              };
            } else {
              return {'status': false, 'message': 'Invalid response format'};
            }
          }
        }
        print('❌ [FleetService] Retry failed, returning error');
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }
      if (response.statusCode == 200) {
        print('✅ [FleetService] Request successful, returning data');
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          return {
            'status': data['result']['status'] == true,
            'message': data['result']['message'] ?? '',
            'data': data['result']['data'],
          };
        } else {
          return {'status': false, 'message': 'Invalid response format'};
        }
      } else {
        print(
          '❌ [FleetService] Request failed with status: ${response.statusCode}',
        );
        return {
          'status': false,
          'message':
              'Failed to update vehicle status. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [FleetService] Network error: $e');
      return {'status': false, 'message': 'Network error: $e'};
    }
  }
}
