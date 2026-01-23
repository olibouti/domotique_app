import 'esp_pin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ESPDevice {
  final String name;
  final String localIP;
  final String publicIP;
  List<ESPPin> pins;

  ESPDevice({
    required this.name,
    required this.localIP,
    required this.publicIP,
    required this.pins,
  });

  Future<Map<String, bool>> fetchLedStatus() async {
  final url = Uri.parse("$localIP/status");
  final response = await http.get(url).timeout(Duration(seconds: 3));
  if (response.statusCode != 200) throw Exception("Erreur HTTP");
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return data.map((key, value) => MapEntry(key, value == 1));
}

}
