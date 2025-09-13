import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

class ApiService {
  final _base = Uri.parse(AppConfig.baseUrl);

  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    final uri = Uri(
      scheme: _base.scheme,
      host: _base.host,
      port: _base.port == 0 ? null : _base.port,
      path: '${_base.path}$path',
      queryParameters: query,
    );
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = json.decode(res.body);
      if (body is List) return body;
      if (body is Map && body['data'] is List) return body['data'];
      return [];
    }
    throw Exception('GET $path failed: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> getOne(String path) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = json.decode(res.body);
      return (body is Map<String, dynamic>) ? body : {'data': body};
    }
    throw Exception('GET $path failed: ${res.statusCode}');
  }
}
