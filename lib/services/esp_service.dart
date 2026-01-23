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
  final rawSsid = await NetworkService.getWifiName();  // peut contenir des quotes
  final savedSsid = await DBHelper.getWifiName();

  // Nettoyage : trim + enlever guillemets doubles ou simples
  final currentSsid = rawSsid?.replaceAll('"', '').replaceAll("'", "").trim();



  if (currentSsid != null && savedSsid != null &&
      currentSsid.toLowerCase() == savedSsid.toLowerCase()) {
    final url = Uri.parse('${device.localIP}$path');
    logger.i('💡 URL choisie (locale) : $url');
    return url;
  }

  final url = Uri.parse('${device.publicIP}$path');
  logger.i('💡 URL choisie (publique) : $url');
  return url;
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
