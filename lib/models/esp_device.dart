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

  /// ⚡ Nouveau : constructeur async pour charger les pins depuis la DB
  static Future<ESPDevice> fromDbWithPins(Map<String, dynamic> map) async {
    final device = ESPDevice.fromDb(map);
    final pinsData = await DBHelper.getPins(device.id!);
    device.pins.addAll(pinsData.map((p) => ESPPin.fromDb(p)));
    return device;
  }
}
