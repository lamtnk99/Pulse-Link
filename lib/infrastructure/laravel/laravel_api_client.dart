import 'dart:convert';

import 'package:http/http.dart' as http;

class LaravelApiClient {
  LaravelApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final Uri baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _httpClient.get(
      _resolve(path),
      headers: await _headers(),
    );
    return _decodeObject(response);
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await _httpClient.get(
      _resolve(path),
      headers: await _headers(),
    );
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _httpClient.post(
      _resolve(path),
      headers: await _headers(),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    return _decodeObject(response);
  }

  /// Tải một tệp lên qua multipart/form-data (ví dụ ảnh CCCD). Trả về JSON body.
  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, String> fields = const {},
  }) async {
    final token = await tokenProvider();
    final request = http.MultipartRequest('POST', _resolve(path))
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(fileField, filePath));

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    return _decodeObject(response);
  }

  Uri _resolve(String path) {
    final cleanBase = baseUrl.toString().replaceFirst(RegExp(r'/$'), '');
    final cleanPath = path.replaceFirst(RegExp(r'^/'), '');
    return Uri.parse('$cleanBase/$cleanPath');
  }

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    _throwIfFailed(response);
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map && decoded['data'] is Map<String, dynamic>) {
      return decoded['data'] as Map<String, dynamic>;
    }
    throw const FormatException('Expected JSON object from Laravel API');
  }

  List<dynamic> _decodeList(http.Response response) {
    _throwIfFailed(response);
    final decoded = jsonDecode(response.body);
    if (decoded is List<dynamic>) return decoded;
    if (decoded is Map && decoded['data'] is List<dynamic>) {
      return decoded['data'] as List<dynamic>;
    }
    throw const FormatException('Expected JSON list from Laravel API');
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw LaravelApiException(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}

class LaravelApiException implements Exception {
  const LaravelApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() => 'LaravelApiException($statusCode): $body';
}
