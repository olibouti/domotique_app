import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/esp_device.dart';
import '../services/network_service.dart';
import 'db_helper.dart';

final logger = Logger();

class ESPService {
  final ESPDevice device;

  ESPService({required this.device});

Future<Uri> _getBaseUrl(String path) async {
  final localUrl = Uri.parse('${device.localIP}$path');
  final publicUrl = Uri.parse('${device.publicIP}$path');

  // 1️⃣ Tentative locale rapide
  try {
    final res = await http
        .get(localUrl)
        .timeout(const Duration(milliseconds: 800));

    if (res.statusCode == 200) {
      logger.i('💡 URL locale OK : $localUrl');
      return localUrl;
    }
  } catch (_) {
    // silence volontaire
  }

  // 2️⃣ Fallback public
  logger.i('💡 Fallback URL publique : $publicUrl');
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
      if (response.statusCode != 200) {
        throw Exception();
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v == 1));
    } catch (e) {
      logger.e("fetchLedStatus error: $e sur url -> $url");
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
