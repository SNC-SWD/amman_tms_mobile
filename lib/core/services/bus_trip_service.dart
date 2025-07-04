import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amman_tms_mobile/core/api/api_config.dart';
import 'package:amman_tms_mobile/core/services/auth_service.dart';

class BusTripService {
  final AuthService _authService;
  String? _sessionId;

  BusTripService({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<String?> _getSessionId() async {
    await _authService.initializeSession();
    _sessionId = _authService.sessionId;
    print(
      '🔑 [BusTripService] Retrieved sessionId from storage: ${_sessionId != null ? 'Found' : 'Not found'}',
    );
    return _sessionId;
  }

  Future<bool> _reAuthenticate() async {
    try {
      print('🔄 [BusTripService] Attempting re-authentication...');
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
        '🔐 [BusTripService] Re-authentication response status: ${response.statusCode}',
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
              '✅ [BusTripService] Re-authentication successful, new sessionId obtained',
            );
            return true;
          }
        }
        print(
          '❌ [BusTripService] Re-authentication failed: No sessionId in cookies',
        );
      } else {
        print(
          '❌ [BusTripService] Re-authentication failed: Status ${response.statusCode}',
        );
      }
      return false;
    } catch (e) {
      print('❌ [BusTripService] Re-authentication error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getBusTrips({
    String? busId,
    String? startDate,
    String? endDate,
    String? userId,
    String? busStatusSeq,
  }) async {
    try {
      print('🚌 [BusTripService] Fetching bus trips');

      String? sessionId = await _getSessionId();

      // direct reAuthenticate
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        print(
          '❌ [BusTripService] Re-authentication failed, cannot proceed with request',
        );
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }
      sessionId = _sessionId;

      // if (sessionId == null) {
      //   print(
      //     '⚠️ [BusTripService] No sessionId found, attempting re-authentication',
      //   );
      //   final reAuthSuccess = await _reAuthenticate();
      //   if (!reAuthSuccess) {
      //     print(
      //       '❌ [BusTripService] Re-authentication failed, cannot proceed with request',
      //     );
      //     return {
      //       'status': false,
      //       'message': 'Authentication failed. Please login again.',
      //     };
      //   }
      //   sessionId = _sessionId;
      // }

      final Map<String, String> queryParams = {};
      if (busId != null && busId.isNotEmpty) queryParams['bus_id'] = busId;
      if (startDate != null && startDate.isNotEmpty)
        queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty)
        queryParams['end_date'] = endDate;
      if (userId != null && userId.isNotEmpty) queryParams['user_id'] = userId;
      if (busStatusSeq != null && busStatusSeq.isNotEmpty)
        queryParams['status_bus_trip_sec'] = busStatusSeq;

      Uri uri;
      if (queryParams.isNotEmpty) {
        uri = Uri.parse(
          '${ApiConfig.baseUrl}/bus-trip/list',
        ).replace(queryParameters: queryParams);
      } else {
        uri = Uri.parse('${ApiConfig.baseUrl}/bus-trip/list');
      }

      print(
        '🌐 [BusTripService] Making request to: [32m[1m[4m${uri.toString()}[0m',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$sessionId',
        },
      );

      print('📡 [BusTripService] Response status: ${response.statusCode}');

      if (response.statusCode == 404) {
        print(
          '⚠️ [BusTripService] Not Found (404), attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          print(
            '🔄 [BusTripService] Re-authentication successful, retrying request',
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
            '📡 [BusTripService] Retry response status: ${retryResponse.statusCode}',
          );

          if (retryResponse.statusCode == 200) {
            print('✅ [BusTripService] Retry successful, returning data');
            return jsonDecode(retryResponse.body);
          }
        }
        print('❌ [BusTripService] Retry failed, returning error');
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      if (response.statusCode == 200) {
        print('✅ [BusTripService] Request successful, returning data');
        return jsonDecode(response.body);
      } else {
        print(
          '❌ [BusTripService] Request failed with status: ${response.statusCode}',
        );
        return {
          'status': false,
          'message':
              'Failed to fetch bus trips. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [BusTripService] Network error: $e');
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createBusTrip({
    required String date,
    required int fromLocation,
    required int toLocation,
    required int fleetId,
    required int passengerQuantity,
  }) async {
    try {
      print('🚌 [BusTripService] Creating bus trip...');
      print('📅 Date: $date');
      print('📍 From: $fromLocation');
      print('📍 To: $toLocation');
      print('🚌 Fleet: $fleetId');
      print('👥 Passengers: $passengerQuantity');

      // Get sessionId from AuthService's local storage
      String? sessionId = await _getSessionId();

      // direct reAuthenticate
      final reAuthSuccess = await _reAuthenticate();
      if (!reAuthSuccess) {
        print(
          '❌ [BusTripService] Re-authentication failed, cannot proceed with request',
        );
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }
      sessionId = _sessionId;

      // If no sessionId, try to re-authenticate
      // if (sessionId == null) {
      //   print(
      //     '⚠️ [BusTripService] No sessionId found, attempting re-authentication',
      //   );
      //   final reAuthSuccess = await _reAuthenticate();
      //   if (!reAuthSuccess) {
      //     print(
      //       '❌ [BusTripService] Re-authentication failed, cannot proceed with request',
      //     );
      //     return {
      //       'status': false,
      //       'message': 'Authentication failed. Please login again.',
      //     };
      //   }
      //   sessionId = _sessionId;
      // }

      // Step 1: Call /bus/wizard
      final wizardUri = Uri.parse('${ApiConfig.baseUrl}/bus/wizard');
      print('🌐 [BusTripService] Making request to: ${wizardUri.toString()}');

      var wizardResponse = await http.post(
        wizardUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$sessionId',
        },
        body: jsonEncode({
          'date': date,
          'from_location': fromLocation,
          'to_location': toLocation,
          'fleet_type': fleetId,
        }),
      );

      // Handle 404 response for wizard endpoint
      if (wizardResponse.statusCode == 404) {
        print(
          '⚠️ [BusTripService] Wizard endpoint returned 404, attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (!reAuthSuccess) {
          return {
            'status': false,
            'message': 'Authentication failed. Please login again.',
          };
        }
        sessionId = _sessionId;

        // Retry wizard request with new session
        wizardResponse = await http.post(
          wizardUri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': 'session_id=$sessionId',
          },
          body: jsonEncode({
            'date': date,
            'from_location': fromLocation,
            'to_location': toLocation,
            'fleet_type': fleetId,
          }),
        );
      }

      print(
        '📡 [BusTripService] Wizard response status: ${wizardResponse.statusCode}',
      );

      if (wizardResponse.statusCode == 200) {
        final wizardData = jsonDecode(wizardResponse.body);
        return {
          'status': wizardData['result']?['status'] == 'success',
          'data': wizardData,
          'message': wizardData['result']?['message'] ?? '',
        };
      } else {
        print(
          '❌ [BusTripService] Wizard failed with status: ${wizardResponse.statusCode}',
        );
        return {
          'status': false,
          'message':
              'Failed to create bus trip. Status: ${wizardResponse.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [BusTripService] Error creating bus trip: $e');
      return {'status': false, 'message': 'Error creating bus trip: $e'};
    }
  }

  Future<Map<String, dynamic>> checkoutBusTrip({
    required String searchResultId,
    required int passengerQuantity,
  }) async {
    try {
      print('🚌 [BusTripService] Checkout bus trip...');
      print('🔎 searchResultId: $searchResultId');
      print('👥 Passengers: $passengerQuantity');

      String? sessionId = await _getSessionId();
      if (sessionId == null) {
        print(
          '⚠️ [BusTripService] No sessionId found, attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (!reAuthSuccess) {
          print(
            '❌ [BusTripService] Re-authentication failed, cannot proceed with request',
          );
          return {
            'status': false,
            'message': 'Authentication failed. Please login again.',
          };
        }
        sessionId = _sessionId;
      }

      final checkoutUri = Uri.parse('${ApiConfig.baseUrl}/booking/checkout');
      print('🌐 [BusTripService] Making request to: ${checkoutUri.toString()}');

      var checkoutResponse = await http.post(
        checkoutUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$sessionId',
        },
        body: jsonEncode({
          'search_result_id': searchResultId,
          'passenger_quantity': passengerQuantity,
        }),
      );

      // Handle 404 response for checkout endpoint
      if (checkoutResponse.statusCode == 404) {
        print(
          '⚠️ [BusTripService] Checkout endpoint returned 404, attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (!reAuthSuccess) {
          return {
            'status': false,
            'message': 'Authentication failed. Please login again.',
          };
        }
        sessionId = _sessionId;

        // Retry checkout request with new session
        checkoutResponse = await http.post(
          checkoutUri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': 'session_id=$sessionId',
          },
          body: jsonEncode({
            'search_result_id': searchResultId,
            'passenger_quantity': passengerQuantity,
          }),
        );
      }

      print(
        '📡 [BusTripService] Checkout response status: ${checkoutResponse.statusCode}',
      );

      if (checkoutResponse.statusCode == 200) {
        print('✅ [BusTripService] Bus trip checked out successfully');
        return {'status': true, 'message': 'Bus trip checked out successfully'};
      } else {
        print(
          '❌ [BusTripService] Checkout failed with status: ${checkoutResponse.statusCode}',
        );
        return {
          'status': false,
          'message':
              'Failed to checkout bus trip. Status: ${checkoutResponse.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [BusTripService] Error during checkout: $e');
      return {'status': false, 'message': 'Error during checkout: $e'};
    }
  }

  Future<Map<String, dynamic>> getPlanTrips({
    required String tripDate,
    String? userId,
    String? routeId,
  }) async {
    try {
      print(
        '🚌 [BusTripService] Fetching plan trips for date: $tripDate, userId: $userId, routeId: $routeId',
      );
      String? sessionId = await _getSessionId();
      if (sessionId == null) {
        print(
          '⚠️ [BusTripService] No sessionId found, attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (!reAuthSuccess) {
          print(
            '❌ [BusTripService] Re-authentication failed, cannot proceed with request',
          );
          return {
            'status': false,
            'message': 'Authentication failed. Please login again.',
          };
        }
        sessionId = _sessionId;
      }
      // Build query string
      String query = 'trip_date=$tripDate';
      if (userId != null && userId.isNotEmpty) {
        query += '&user_id=$userId';
      }
      if (routeId != null && routeId.isNotEmpty) {
        query += '&route_id=$routeId';
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}/bus-search/list?$query');
      print(
        '🌐 [BusTripService] Making request to: \u001b[32m\u001b[1m\u001b[4m${uri.toString()}\u001b[0m',
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$sessionId',
        },
      );
      print(
        '📡 [BusTripService] Response status: \u001b[32m${response.statusCode}\u001b[0m',
      );
      if (response.statusCode == 404) {
        print(
          '⚠️ [BusTripService] Not Found (404), attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          print(
            '🔄 [BusTripService] Re-authentication successful, retrying request',
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
            '📡 [BusTripService] Retry response status: ${retryResponse.statusCode}',
          );
          if (retryResponse.statusCode == 200) {
            print('✅ [BusTripService] Retry successful, returning data');
            return jsonDecode(retryResponse.body);
          }
        }
        print('❌ [BusTripService] Retry failed, returning error');
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }
      if (response.statusCode == 200) {
        print('✅ [BusTripService] Request successful, returning data');
        return jsonDecode(response.body);
      } else {
        print(
          '❌ [BusTripService] Request failed with status: ${response.statusCode}',
        );
        return {
          'status': false,
          'message':
              'Failed to fetch plan trips. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [BusTripService] Network error: $e');
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateBusTripState({
    required int tripId,
    required String state,
  }) async {
    try {
      print(
        '🚌 [BusTripService] Updating bus trip state for tripId: $tripId to state: $state',
      );

      String? sessionId = await _getSessionId();
      if (sessionId == null) {
        print(
          '⚠️ [BusTripService] No sessionId found, attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (!reAuthSuccess) {
          print(
            '❌ [BusTripService] Re-authentication failed, cannot proceed with request',
          );
          return {
            'status': false,
            'message': 'Authentication failed. Please login again.',
          };
        }
        sessionId = _sessionId;
      }

      final Uri uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.updateBusTripState}/$tripId/update_state',
      );
      print('🌐 [BusTripService] Making PATCH request to: ${uri.toString()}');

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'session_id=$sessionId',
        },
        body: jsonEncode({'state': state}),
      );

      print('📡 [BusTripService] Response status: ${response.statusCode}');

      if (response.statusCode == 404) {
        print(
          '⚠️ [BusTripService] Not Found (404), attempting re-authentication',
        );
        final reAuthSuccess = await _reAuthenticate();
        if (reAuthSuccess) {
          print(
            '🔄 [BusTripService] Re-authentication successful, retrying request',
          );
          final retryResponse = await http.patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Cookie': 'session_id=$_sessionId',
            },
            body: jsonEncode({'state': state}),
          );
          print(
            '📡 [BusTripService] Retry response status: ${retryResponse.statusCode}',
          );
          if (retryResponse.statusCode == 200) {
            print('✅ [BusTripService] Retry successful, returning success');
            return {
              'status': true,
              'message': 'Trip state updated successfully',
            };
          }
        }
        print('❌ [BusTripService] Retry failed, returning error');
        return {
          'status': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      if (response.statusCode == 200) {
        print('✅ [BusTripService] Request successful, returning success');
        return {'status': true, 'message': 'Trip state updated successfully'};
      } else {
        print(
          '❌ [BusTripService] Request failed with status: ${response.statusCode}',
        );
        return {
          'status': false,
          'message':
              'Failed to update trip state. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [BusTripService] Network error: $e');
      return {'status': false, 'message': 'Network error: $e'};
    }
  }
}
