import 'esp_pin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ESPDevice {
  final int? id;
  final String name;
  final String localIP;
  final String publicIP;
  final List<ESPPin> pins;

  ESPDevice({
    this.id,
    required this.name,
    required this.localIP,
    required this.publicIP,
    List<ESPPin>? pins,
  }) : pins = pins ?? [];

  /// Constructeur dédié SQLite / service
  factory ESPDevice.fromDb(Map<String, dynamic> map) {
    return ESPDevice(
      id: map['id'],
      name: map['name'],
      localIP: map['localIP'],
      publicIP: map['publicIP'],
    );
  }

  Future<Map<String, bool>> fetchLedStatus() async {
    final url = Uri.parse('$localIP/status');
    final response =
        await http.get(url).timeout(const Duration(seconds: 3));

    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data.map(
      (key, value) => MapEntry(key, value == 1),
    );
  }
}
