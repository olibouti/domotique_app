import 'package:flutter/material.dart';
import '../models/esp_pin.dart';
import '../services/db_helper.dart';
import 'package:material_symbols_icons/symbols.dart';

class PinsSettingsScreen extends StatefulWidget {
  final int deviceId;

  const PinsSettingsScreen({super.key, required this.deviceId});

  @override
  State<PinsSettingsScreen> createState() => _PinsSettingsScreenState();
}

class _PinsSettingsScreenState extends State<PinsSettingsScreen> {
  List<ESPPin> pins = [];

  final List<String> gpioOptions = [
    'D0',
    'D1',
    'D2',
    'D3',
    'D4',
    'D5',
    'D6',
    'D7',
    'D8',
  ];

  final Map<String, String> pinTypeMap = {
    "Sortie": "OUTPUT",
    "Entrée digitale": "INPUT_DIGITAL",
    "Entrée analogique": "INPUT_ANALOG",
    "Capteur DHT": "SENSOR_DHT",
    "Capteur Ultrason": "SENSOR_ULTRASONIC",
  };
  late final Map<String, String> pinTypeMapFr = {
    for (var e in pinTypeMap.entries) e.value: e.key,
  };

  final Map<String, List<String>> sensorTypeMap = {
    "SENSOR_DHT": ["DHT22"],
    "SENSOR_ULTRASONIC": ["HC-SR04"],
  };
  late final Map<String, String> sensorTypeMapFr = {
    "DHT22": "DHT22",
    "HC-SR04": "Ultrason",
  };

  final Map<String, String> iconOptionsMap = {
    'device_hub': 'Hub',
    'bolt': 'Éclair',
    'power': 'Énergie',
    'water_drop': 'Goutte',
    'water_pump': 'Pompe',
    'pool': 'Piscine',
    'fan': 'Ventilateur',
    'motor': 'Moteur',
    'ac_unit': 'Clim',
    'lightbulb': 'Ampoule',
    'flash_on': 'Flash',
    'heating': 'Chauffage',
  };

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    final pinsData = await DBHelper.getPins(widget.deviceId);
    setState(() {
      pins = pinsData.map((p) => ESPPin.fromDb(p)).toList();
    });
  }

  Future<void> _save() async {
    final db = await DBHelper.getDb();
    await db.delete('pins', where: 'deviceId=?', whereArgs: [widget.deviceId]);
    for (var pin in pins) {
      await DBHelper.insertPin(pin, widget.deviceId);
    }
    Navigator.pop(context, true);
  }

  IconData _iconFromString(String name) {
    switch (name) {
      case 'device_hub':
        return Icons.device_hub;
      case 'bolt':
        return Icons.bolt;
      case 'power':
        return Icons.power;
      case 'water_drop':
        return Icons.water_drop;
      case 'water_pump':
        return Symbols.water_pump;
      case 'pool':
        return Symbols.pool;
      case 'fan':
        return Symbols.mode_fan;
      case 'motor':
        return Symbols.electric_meter;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'flash_on':
        return Icons.flash_on;
      case 'heating':
        return Symbols.heat;
      default:
        return Icons.device_hub;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuration des pins"),
        actions: [IconButton(icon: const Icon(Icons.save),  onPressed: () async {  await _save(); },)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // Nouvelle pin par défaut OUTPUT
            pins.add(ESPPin(name: "Nouvelle pin", pin: "D0", type: "OUTPUT"));
          });
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pins.length + 1,
        itemBuilder: (_, index) {
          if (index == pins.length) return const SizedBox(height: 80);
          final pin = pins[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Nom
                  TextField(
                    controller: TextEditingController(text: pin.name),
                    decoration: const InputDecoration(
                      labelText: "Nom",
                      prefixIcon: Icon(Icons.edit),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => pin.name = v,
                  ),
                  const SizedBox(height: 12),

                  // GPIO
                  DropdownButtonFormField<String>(
                    value: pin.pin,
                    decoration: const InputDecoration(
                      labelText: "GPIO",
                      border: OutlineInputBorder(),
                    ),
                    items: gpioOptions
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => pin.pin = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Type pin
                  DropdownButtonFormField<String>(
                    value: pinTypeMapFr[pin.type],
                    decoration: const InputDecoration(
                      labelText: "Type de pin",
                      border: OutlineInputBorder(),
                    ),
                    items: pinTypeMap.keys
                        .map(
                          (fr) => DropdownMenuItem(value: fr, child: Text(fr)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          // Met à jour le type réel
                          pin.type = pinTypeMap[v]!;

                          // Si ce n’est plus un capteur, on reset sensorType
                          if (!sensorTypeMap.containsKey(pin.type)) {
                            pin.sensorType = null;
                          } else {
                            // Si c’est un capteur, on assigne le sensorType par défaut si null
                            pin.sensorType ??= sensorTypeMap[pin.type]!.first;
                          }
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Type capteur (si applicable)
                  if (sensorTypeMap.containsKey(pin.type))
                    DropdownButtonFormField<String>(
                      value: pin.sensorType != null
                          ? sensorTypeMapFr[pin.sensorType!]
                          : sensorTypeMapFr[sensorTypeMap[pin.type]!.first],
                      decoration: const InputDecoration(
                        labelText: "Type de capteur",
                        border: OutlineInputBorder(),
                      ),
                      items: sensorTypeMap[pin.type]!
                          .map(
                            (esp) => DropdownMenuItem(
                              value: sensorTypeMapFr[esp],
                              child: Text(sensorTypeMapFr[esp]!),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null)
                          setState(() {
                            // Corrige le mapping pour ne chercher que dans le type actuel
                            pin.sensorType = sensorTypeMap[pin.type]!
                                .firstWhere((esp) => sensorTypeMapFr[esp] == v);
                          });
                      },
                    ),
                  const SizedBox(height: 12),

                  // Icon picker
                  DropdownButtonFormField<String>(
                    value: pin.iconName,
                    decoration: const InputDecoration(
                      labelText: "Icône",
                      border: OutlineInputBorder(),
                    ),
                    items: iconOptionsMap.keys
                        .map(
                          (iconStr) => DropdownMenuItem(
                            value: iconStr,
                            child: Row(
                              children: [
                                Icon(_iconFromString(iconStr)),
                                const SizedBox(width: 8),
                                Text(iconOptionsMap[iconStr]!),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => pin.iconName = v);
                    },
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => pins.removeAt(index)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
