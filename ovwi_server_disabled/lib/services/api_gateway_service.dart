import 'package:http/http.dart' as http;
import 'dart:convert';

class APIGatewayService {
  final String clinicflowacBaseUrl;

  APIGatewayService({this.clinicflowacBaseUrl = 'http://disabled:8083'});

  Future<dynamic> proxyRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    required String apiKey,
  }) async {
    try {
      final url = Uri.parse(clinicflowacBaseUrl + path);
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      };

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: jsonEncode(body ?? {}),
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: jsonEncode(body ?? {}),
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('ClinicFlowAC error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getPatients(String apiKey) async {
    return proxyRequest(
      method: 'GET',
      path: '/api/v1/patients',
      apiKey: apiKey,
    );
  }

  Future<dynamic> createPatient(
    String apiKey,
    Map<String, dynamic> data,
  ) async {
    return proxyRequest(
      method: 'POST',
      path: '/api/v1/patients',
      body: data,
      apiKey: apiKey,
    );
  }

  Future<dynamic> getAppointments(String apiKey) async {
    return proxyRequest(
      method: 'GET',
      path: '/api/v1/appointments',
      apiKey: apiKey,
    );
  }

  Future<dynamic> createAppointment(
    String apiKey,
    Map<String, dynamic> data,
  ) async {
    return proxyRequest(
      method: 'POST',
      path: '/api/v1/appointments',
      body: data,
      apiKey: apiKey,
    );
  }

  Future<dynamic> getDoctors(String apiKey) async {
    return proxyRequest(
      method: 'GET',
      path: '/api/v1/doctors',
      apiKey: apiKey,
    );
  }

  Future<dynamic> createDoctor(
    String apiKey,
    Map<String, dynamic> data,
  ) async {
    return proxyRequest(
      method: 'POST',
      path: '/api/v1/doctors',
      body: data,
      apiKey: apiKey,
    );
  }
}








