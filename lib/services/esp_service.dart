import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/esp_device.dart';
import 'network_service.dart';

final logger = Logger();

class ESPService {
  final ESPDevice device;

  ESPService({required this.device});

Future<Uri> _getBaseUrl(String path) async {
  // 1️⃣ essayer LOCAL
  try {
    final localUrl = Uri.parse("${device.localIP}$path");
    final res = await http
        .get(localUrl)
        .timeout(const Duration(seconds: 800));
    if (res.statusCode == 200) {
      logger.i("Using LOCAL → $localUrl");
      return localUrl;
    }
  } catch (_) {
    // ignore → fallback
  }

  // 2️⃣ fallback PUBLIC
  final publicUrl = Uri.parse("${device.publicIP}$path");
  logger.i("Using PUBLIC → $publicUrl");
  return publicUrl;
}


  // =============================
  // TOGGLE
  // =============================
  Future<bool> togglePin(String pin, bool turnOn) async {
    final state = turnOn ? "on" : "off";
    final url = await _getBaseUrl("/led?pin=$pin&state=$state");

    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      logger.e("togglePin error: $e");
      return false;
    }
  }

  // =============================
  // STATUS
  // =============================
  Future<Map<String, bool>> fetchLedStatus() async {
    final url = await _getBaseUrl("/status");

    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) throw Exception();

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v == 1));
    } catch (e) {
      logger.e("fetchLedStatus error: $e");
      return {};
    }
  }

  // =============================
  // CHECK
  // =============================
  Future<bool> checkConnection() async {
    try {
      final url = await _getBaseUrl("/status");
      final response =
          await http.get(url).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
