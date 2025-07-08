import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../api/api_config.dart';
import '../../models/route_line.dart' as model_route_line;
import '../../models/fleet.dart';
import '../../models/bus_point.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class RouteService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService;
  SharedPreferences? _prefs;
  String? _sessionId;

  RouteService({AuthService? authService})
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
      '🔑 [RouteService] Retrieved sessionId from storage: ${_sessionId != null ? 'Found' : 'Not found'}',
    );
    return _sessionId;
  }

  Future<bool> _reAuthenticate() async {
    try {
      print('🔄 [RouteService] Attempting re-authentication...');
      final Uri authUri = Uri.parse('${ApiConfig.connectionEndpoint}');

      print(
        '🔑 [RouteService] Re-authentication request body: Username: ${_authService.username}, Password: ${_authService.password}',
      );

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
        '🔐 [RouteService] Re-authentication response status: ${response.statusCode}',
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
              '✅ [RouteService] Re-authentication successful, new sessionId obtained',
            );
            return true;
          }
        }
        print(
          '❌ [RouteService] Re-authentication failed: No sessionId in cookies',
        );
      } else {
        print(
          '❌ [RouteService] Re-authentication failed: Status ${response.statusCode}',
        );
      }
      return false;
    } catch (e) {
      print('❌ [RouteService] Re-authentication error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getRoutes({
    String? driverId,
    int? page,
    int? perPage,
    bool? pagination,
  }) async {
    try {
      print(
        '🛣️ [RouteService] Fetching routes${driverId != null ? ' for driver: $driverId' : ''}${page != null ? ' page: $page' : ''}',
      );

      // Ensure session is valid before making API call
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        print(
          '❌ [RouteService] Re-authentication failed, cannot proceed with request',
        );
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      final Map<String, String> queryParams = {};
      if (driverId != null) {
        queryParams.addAll({
          'driver_id': driverId,
          'is_driver': 'true',
          'user_id': driverId,
        });
      }
      if (page != null) {
        queryParams['page'] = page.toString();
      }
      if (perPage != null) {
        queryParams['per_page'] = perPage.toString();
      }
      if (pagination == true) {
        queryParams['pagination'] = '1';
      }

      final Uri uri = Uri.parse(
        '$baseUrl${ApiConfig.getRoutes}',
      ).replace(queryParameters: queryParams);

      print('🌐 [RouteService] Making request to: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$_sessionId',
        },
      );

      print('📡 [RouteService] Response status: ${response.statusCode}');

      if (response.statusCode == 404) {
        print(
          '⚠️ [RouteService] Not Found (404), attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          print(
            '🔄 [RouteService] Re-authentication successful, retrying request',
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
            '📡 [RouteService] Retry response status: ${retryResponse.statusCode}',
          );

          if (retryResponse.statusCode == 200) {
            print('✅ [RouteService] Retry successful, returning data');
            return jsonDecode(retryResponse.body);
          }
        }
        print('❌ [RouteService] Retry failed, returning error');
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      final responseData = jsonDecode(response.body);
      return {
        'status': response.statusCode == 200,
        'data': responseData['data'] ?? [],
        'message': responseData['message'] ?? 'Unknown error occurred',
      };
    } catch (e) {
      print('❌ [RouteService] Error fetching routes: $e');
      return {'status': false, 'data': null, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createRoute({
    required BusPoint boardingPoint,
    required BusPoint droppingPoint,
    required Fleet fleet,
    required String startTime,
    required String endTime,
    required List<model_route_line.RouteLine> routeLines,
    required List<BusPoint> busPoints,
  }) async {
    try {
      // Ensure session is valid before making API call
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        print(
          '❌ [RouteService] Re-authentication failed, cannot proceed with request',
        );
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      // Convert time strings to required format (e.g., "09:45" to "9.45")
      String convertTimeFormat(String time) {
        final parts = time.split(':');
        final hours = int.parse(parts[0]);
        final minutes = parts[1];
        return '$hours.$minutes';
      }

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.routeCreate}'),
        headers: {
          'Content-Type': 'application/json',
          if (_sessionId != null) 'Cookie': 'session_id=$_sessionId',
        },
        body: jsonEncode({
          'baording_id': boardingPoint.id,
          'dropping_id': droppingPoint.id,
          'fleet_id': fleet.id,
          'str_time': convertTimeFormat(startTime),
          'end_time': convertTimeFormat(endTime),
          'route_lines': routeLines
              .map(
                (line) => {
                  'bording_from': busPoints
                      .firstWhere((p) => p.name == line.from)
                      .id,
                  'to': busPoints.firstWhere((p) => p.name == line.to).id,
                  'start_times': convertTimeFormat(line.startTime!),
                  'end_times': convertTimeFormat(line.endTime!),
                },
              )
              .toList(),
        }),
      );

      if (response.statusCode == 404) {
        print(
          '⚠️ [RouteService] Session expired, attempting re-authentication...',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          // Retry the request with new session
          return createRoute(
            boardingPoint: boardingPoint,
            droppingPoint: droppingPoint,
            fleet: fleet,
            startTime: startTime,
            endTime: endTime,
            routeLines: routeLines,
            busPoints: busPoints,
          );
        }
      }

      final responseData = jsonDecode(response.body);
      return {
        'status': response.statusCode == 200,
        'data': responseData,
        'message': responseData['message'] ?? 'Unknown error occurred',
      };
    } catch (e) {
      return {'status': false, 'data': null, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateRoute({
    required String name,
    required int routeId,
    required int boardingId,
    required int droppingId,
    required int fleetId,
    required String startTime,
    required String endTime,
    required List<Map<String, dynamic>> routeLines,
  }) async {
    String convertTimeFormat(String time) {
      final parts = time.split(':');
      final hours = int.parse(parts[0]);
      final minutes = parts[1];
      return '$hours.$minutes';
    }

    try {
      // Ensure session is valid before making API call
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        print(
          '❌ [RouteService] Re-authentication failed, cannot proceed with request',
        );
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      String? sessionId = _sessionId;

      print('📤 [RouteService] Updating route with ID: $routeId');
      print('📝 [RouteService] Request payload:');
      print('  - Name: $name');
      print('  - Boarding ID: $boardingId');
      print('  - Dropping ID: $droppingId');
      print('  - Fleet ID: $fleetId');
      print('  - Start Time: $startTime');
      print('  - End Time: $endTime');
      print('  - Route Lines: ${routeLines.length}');

      final response = await http
          .put(
            Uri.parse('$baseUrl/route/update/$routeId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Cookie': 'session_id=$sessionId',
            },
            body: jsonEncode({
              'name': name,
              'baording_id': boardingId,
              'dropping_id': droppingId,
              'fleet_id': fleetId,
              'str_time': convertTimeFormat(startTime),
              'end_time': convertTimeFormat(endTime),
              'route_lines': routeLines,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 [RouteService] Update response status: ${response.statusCode}');
      print('📥 [RouteService] Update response body: ${response.body}');

      if (response.statusCode == 404) {
        print(
          '⚠️ [RouteService] Session expired, attempting re-authentication...',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          print(
            '✅ [RouteService] Re-authentication successful, retrying update...',
          );

          print(
            '✅ [RouteService] Payload: ${jsonEncode({'name': name, 'boarding_id': boardingId, 'dropping_id': droppingId, 'fleet_id': fleetId, 'str_time': convertTimeFormat(startTime), 'end_time': convertTimeFormat(endTime), 'route_lines': routeLines})}',
          );

          return updateRoute(
            name: name,
            routeId: routeId,
            boardingId: boardingId,
            droppingId: droppingId,
            fleetId: fleetId,
            startTime: startTime,
            endTime: endTime,
            routeLines: routeLines,
          );
        } else {
          print('❌ [RouteService] Re-authentication failed');
          return {'status': false, 'message': 'Failed to re-authenticate'};
        }
      }

      final data = jsonDecode(response.body);
      return {
        'status': response.statusCode == 200,
        'message': data['message'] ?? 'Unknown error occurred',
        'data': data['data'],
      };
    } catch (e) {
      print('❌ [RouteService] Error updating route: $e');
      return {
        'status': false,
        'message': 'Failed to update route: ${e.toString()}',
      };
    }
  }
}
