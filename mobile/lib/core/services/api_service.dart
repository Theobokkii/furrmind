import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/distortion_result.dart';
class ApiService {
  String _baseUrl;
  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? 'http://10.0.2.2:8000';
  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    Hive.openBox('settings').then((box) => box.put('apiBaseUrl', _baseUrl));
  }
  Future<void> loadSavedUrl() async {
    final box = await Hive.openBox('settings');
    final saved = box.get('apiBaseUrl');
    if (saved != null) _baseUrl = saved;
  }
  Future<PredictApiResult> predict(String text) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('detail') && body['detail'] is Map) {
        final detail = body['detail'];
        if (detail['guardrail'] == 'crisis') {
          return PredictApiResult.crisis(
            message: detail['message'] ?? '',
            resources: (detail['resources'] as List?)?.cast<String>() ?? [],
            action: detail['action'] ?? '',
          );
        }
      }
      final distortions = (body['distortions'] as List)
          .map((d) => DistortionResult.fromJson(d))
          .toList();
      return PredictApiResult.success(distortions);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Prediction failed: ${response.body}',
      );
    }
  }
  Future<ReframeResult> reframe(String text, List<String> distortions) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reframe'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'detected_distortions': distortions}),
    );
    if (response.statusCode == 200) {
      return ReframeResult.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Reframe failed: ${response.body}',
      );
    }
  }
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
class PredictApiResult {
  final List<DistortionResult>? distortions;
  final bool isCrisis;
  final String? crisisMessage;
  final List<String>? crisisResources;
  final String? crisisAction;
  PredictApiResult.success(this.distortions)
    : isCrisis = false,
      crisisMessage = null,
      crisisResources = null,
      crisisAction = null;
  PredictApiResult.crisis({
    required String message,
    required List<String> resources,
    required String action,
  }) : distortions = null,
       isCrisis = true,
       crisisMessage = message,
       crisisResources = resources,
       crisisAction = action;
}
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
