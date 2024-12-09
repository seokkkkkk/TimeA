import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timea/core/services/firebase_auth_service.dart';

class ApiClient {
  static const String baseUrl = 'firestore.googleapis.com'; // 호스트만 남김

  // Firebase ID 토큰 가져오기
  Future<String?> _getToken() async {
    return await FirebaseAuthService().getIdToken();
  }

  // 공통 GET 요청 함수
  Future<dynamic> get(
    String path, {
    Map<String, List<String>>? queryParameters,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Firebase ID 토큰이 없습니다.');

    final uri = Uri.https(
      baseUrl,
      '/v1/projects/time-a-42e3d/databases/(default)/documents$path',
      queryParameters,
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    return _handleResponse(response);
  }

  // 공통 POST 요청 함수
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('Firebase ID 토큰이 없습니다.');

    final uri = Uri.https(baseUrl,
        '/v1/projects/time-a-42e3d/databases/(default)/documents$path');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  // 공통 DELETE 요청 함수
  Future<dynamic> delete(String path) async {
    final token = await _getToken();
    if (token == null) throw Exception('Firebase ID 토큰이 없습니다.');

    final uri = Uri.https(baseUrl,
        '/v1/projects/time-a-42e3d/databases/(default)/documents$path');
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    return _handleResponse(response);
  }

  // 공통 UPDATE (PATCH) 요청 함수
  Future<dynamic> update(
    String path,
    Map<String, dynamic> body, {
    Map<String, List<String>>? queryParameters,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Firebase ID 토큰이 없습니다.');

    final uri = Uri.https(
      baseUrl,
      '/v1/projects/time-a-42e3d/databases/(default)/documents$path',
      queryParameters,
    );

    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  // 공통 응답 처리 함수
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } else {
      throw Exception('API 요청 실패: ${response.statusCode}, ${response.body}');
    }
  }
}
