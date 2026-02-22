import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/esp_device.dart';
import '../models/esp_pin.dart';
import 'network_service.dart';
import 'db_helper.dart';

final logger = Logger();

class ESPService {
  final ESPDevice device;

  ESPService({required this.device});

  // =====================================================
  // BASE URL
  // =====================================================
  
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

Future<void> configureAllPins(List<ESPPin> pins) async {
  for (var pin in pins) {
    final uri = await _getBaseUrl(
      "/config?pin=${pin.pin}&mode=${pin.type}",
    );
    await http.get(uri);
  }
}


  // =====================================================
  // HTTP AVEC LOGS
  // =====================================================
  Future<http.Response> _getWithLogging(Uri url) async {
    final stopwatch = Stopwatch()..start();

    // logger.i("➡️ HTTP GET: $url");

    try {
      final response = await http.get(url);

      stopwatch.stop();

      // logger.i(
      //   "⬅️ Response: ${response.statusCode} "
      //   "| ${stopwatch.elapsedMilliseconds}ms",
      // );

      // logger.d("📦 Body: ${response.body}");

      return response;

    } catch (e) {
      stopwatch.stop();
      logger.e(
        "❌ HTTP ERROR after ${stopwatch.elapsedMilliseconds}ms",
      );
      logger.e(e);
      rethrow;
    }
  }

  // =====================================================
  // CONFIGURE PIN SUR ESP
  // =====================================================
  Future<void> configurePin(
      String pin,
      String type,
      String? sensorType,
  ) async {

    final url = await _getBaseUrl(
      "/config?pin=$pin&mode=$type",
    );
logger.i('url : $url');
    try {
      await _getWithLogging(url);
    } catch (e) {
      logger.e("configurePin error: $e");
    }
  }

  // =====================================================
  // TOGGLE PIN
  // =====================================================
  Future<bool> togglePin(String pin, bool turnOn) async {
    final state = turnOn ? "on" : "off";

    final url = await _getBaseUrl(
      "/led?pin=$pin&state=$state",
    );

    try {
      final response = await _getWithLogging(url);
      return response.statusCode == 200;
    } catch (e) {
      logger.e("togglePin error: $e");
      return false;
    }
  }

  // =====================================================
  // FETCH STATUS
  // =====================================================
  Future<List<ESPPin>> fetchLedStatus() async {

    final url = await _getBaseUrl("/status");

    try {
      final response = await _getWithLogging(url);

      if (response.statusCode != 200) {
        throw Exception("HTTP ${response.statusCode}");
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final List<ESPPin> result = [];

      data.forEach((key, value) {

        final localPin = device.pins.firstWhere(
          (p) => p.pin == key,
          orElse: () => ESPPin(
            name: key,
            pin: key,
            type: "UNKNOWN",
          ),
        );

        // OUTPUT
        if (localPin.type == "OUTPUT") {
          result.add(
            ESPPin(
              name: key,
              pin: key,
              type: "OUTPUT",
              state: value == 1 || value == true,
            ),
          );
        }

        // SENSOR
        else if (localPin.type.startsWith("SENSOR")) {
          if (value is num) {
            result.add(
              ESPPin(
                name: key,
                pin: key,
                type: localPin.type,
                sensorType: localPin.sensorType,
                value: value.toDouble(),
              ),
            );
          }
        }

        // INPUT DIGITAL
        else if (localPin.type == "INPUT_DIGITAL") {
          result.add(
            ESPPin(
              name: key,
              pin: key,
              type: "INPUT_DIGITAL",
              value: value == 1 ? 1.0 : 0.0,
            ),
          );
        }
      });

      return result;

    } catch (e) {
      logger.e("fetchLedStatus error: $e");
      return [];
    }
  }

  // =====================================================
  // CHECK CONNECTION
  // =====================================================
  Future<bool> checkConnection() async {
    try {
      final url = await _getBaseUrl("/status");
      final response =
          await _getWithLogging(url);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}