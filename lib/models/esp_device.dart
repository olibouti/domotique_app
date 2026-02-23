import 'esp_pin.dart';
import '../services/db_helper.dart';

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

  /// Constructeur depuis la DB sans pins
  factory ESPDevice.fromDb(Map<String, dynamic> map) {
    return ESPDevice(
      id: map['id'] as int?,
      name: map['name'] as String,
      localIP: map['localIP'] as String,
      publicIP: map['publicIP'] as String,
    );
  }

  /// ⚡ Constructeur async pour charger les pins depuis la DB
  static Future<ESPDevice> fromDbWithPins(Map<String, dynamic> map) async {
    final device = ESPDevice.fromDb(map);
    final pinsData = await DBHelper.getPins(device.id!);
    device.pins.addAll(pinsData.map((p) => ESPPin.fromDb(p)));

    // ⚡ Initialisation des capteurs DS18B20 si présent
    for (var pin in device.pins) {
      if (pin.type == "SENSOR_DS18B20" && pin.value == null) {
        pin.value = double.nan; // valeur initiale inconnue
      }
    }

    return device;
  }

  /// Retourne une pin par son nom GPIO
  ESPPin? getPinByName(String pinName) {
    try {
      return pins.firstWhere((p) => p.pin == pinName);
    } catch (_) {
      return null;
    }
  }

  /// Retourne les pins de type capteur
  List<ESPPin> get sensorPins =>
      pins.where((p) => p.type.startsWith("SENSOR")).toList();

  /// Retourne les pins de type sortie
  List<ESPPin> get outputPins =>
      pins.where((p) => p.type == "OUTPUT").toList();
}