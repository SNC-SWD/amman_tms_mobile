import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amman_tms_mobile/core/api/api_config.dart';

class TraccarService {
  static const String _username = 'admin';
  static const String _password = 'admin';

  static String getBasicAuthHeader() {
    final String credentials = '$_username:$_password';
    return 'Basic ' + base64Encode(utf8.encode(credentials));
  }

  static Future<List<dynamic>> fetchBusPositions(int deviceId) async {
    final String url = '${ApiConfig.baseUrlTraccar}/positions?deviceId=$deviceId';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': getBasicAuthHeader(),
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load positions: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching positions: $e');
      return [];
    }
  }
}