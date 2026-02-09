import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/esp_device.dart';
import '../models/esp_pin.dart';
import '../services/network_service.dart';
import 'db_helper.dart';

final logger = Logger();

class ESPService {
  final ESPDevice device;

  ESPService({required this.device});

  // -----------------------------
  // Choix de l'URL (locale / publique)
  // -----------------------------
  Future<Uri> _getBaseUrl(String path) async {
    final localUrl = Uri.parse('${device.localIP}$path');
    final publicUrl = Uri.parse('${device.publicIP}$path');

    // 1️⃣ Tentative locale rapide
    try {
      final res = await http.get(localUrl).timeout(const Duration(milliseconds: 800));
      if (res.statusCode == 200) {
        return localUrl;
      }
    } catch (_) {}

    // 2️⃣ Fallback publique
    return publicUrl;
  }

  // -----------------------------
  // TOGGLE pin (sortie)
  // -----------------------------
  Future<bool> togglePin(String pin, bool turnOn) async {
    final state = turnOn ? "on" : "off";
    final url = await _getBaseUrl("/led?pin=$pin&state=$state");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      logger.e("togglePin error: $e");
      return false;
    }
  }

  // =============================
// FETCH STATUS
// =============================
Future<List<ESPPin>> fetchLedStatus() async {
  final url = await _getBaseUrl("/status");

  try {
    final response =
        await http.get(url).timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final List<ESPPin> pins = [];

    data.forEach((key, value) {
      if (value is bool || value == 0 || value == 1) {
        pins.add(ESPPin(name: key, pin: key, state: value == true || value == 1));
      } else if (value is num) {
        pins.add(ESPPin(name: key, pin: key, value: value.toDouble(), type: "SENSOR"));
      }
    });

    return pins;
  } catch (e) {
    logger.e("fetchLedStatus error: $e sur url -> $url");
    return [];
  }
}


  // -----------------------------
  // CHECK CONNECTION
  // -----------------------------
  Future<bool> checkConnection() async {
    try {
      final url = await _getBaseUrl("/status");
      final response = await http.get(url).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
