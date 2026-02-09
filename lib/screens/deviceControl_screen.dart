import 'dart:async';
import 'package:flutter/material.dart';
import '../models/esp_device.dart';
import '../models/esp_pin.dart';
import '../services/esp_service.dart';
import '../services/db_helper.dart';
import '../services/notification_service.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:logger/logger.dart';

final logger = Logger();  

class DeviceControlScreen extends StatefulWidget {
  final ESPDevice device;

  const DeviceControlScreen({super.key, required this.device});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late ESPDevice device;
  late ESPService espService;
  bool loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    device = widget.device;
    espService = ESPService(device: device);
    NotificationService().initNotifications();
    _loadStatus();

    // ⚡ rafraîchissement automatique toutes les 5 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadStatus());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final pinsStatusList = await espService.fetchLedStatus();

      setState(() {
        for (var pin in device.pins) {
          final updatedPin = pinsStatusList.firstWhere(
            (p) => p.pin == pin.pin,
            orElse: () => pin,
          );
          pin.state = updatedPin.state;
          pin.value = updatedPin.value;
        }
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        // ⚡ Si c’est un HTTP 502, on marque les capteurs comme inaccessibles
        if (e.toString().contains("HTTP 502")) {
          for (var pin in device.pins) {
            if (pin.type != "OUTPUT") {
              pin.value = double.nan; // on utilise NaN comme indicateur
            }
          }
        }
      });

      NotificationService().show(
        "Erreur",
        "Impossible de récupérer le statut des pins",
      );
    }
  }

  Future<void> _togglePin(ESPPin pin) async {
    if (pin.type != "OUTPUT") return; // seuls les OUTPUT sont toggleables

    try {
      final success = await espService.togglePin(pin.pin, !pin.state);
      if (success) {
        setState(() => pin.state = !pin.state);
        final pinIndex = device.pins.indexOf(pin);
        await DBHelper.updatePinState(pinIndex + 1, pin.state);
      } else {
        NotificationService().show(
          "Erreur",
          "L'ESP n'a pas répondu pour ${pin.name}",
        );
      }
    } catch (e) {
      NotificationService().show(
        "Erreur",
        "Impossible de changer l'état de ${pin.name}",
      );
    }
  }

String _formatPinValue(ESPPin pin) {

  // Pour les sorties
  if (pin.type == "OUTPUT") {
    return pin.state ? "Allumé" : "Éteint";
  }

  // Pour les capteurs
  if (pin.type == "SENSOR") {
    if (pin.value == null) return "Valeur inconnue";
    if (pin.value!.isNaN) return "Capteur inaccessible";

    switch (pin.sensorType) {
      case "DHT22":
        return "${pin.value!.toStringAsFixed(1)} °C";
      case "HC-SR04":
        return "${pin.value!.toStringAsFixed(0)} cm";
      default:
        return pin.value!.toString();
    }
  }

  // Pour les entrées digitales ou analogiques si jamais tu ajoutes un jour
  if (pin.value == null) return "Valeur inconnue";
  if (pin.value!.isNaN) return "Valeur invalide";

  switch (pin.type) {
    case "INPUT_DIGITAL":
      return pin.value! > 0 ? "Haut" : "Bas";
    case "INPUT_ANALOG":
      return pin.value!.toStringAsFixed(0);
    default:
      return pin.value!.toString();
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStatus),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: device.pins.length,
              itemBuilder: (context, index) {
                final pin = device.pins[index];

                return Card(
                  color: Colors.grey[100],
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      _iconFromString(pin.iconName),
                      size: 40,
                      color: pin.type == "OUTPUT"
                          ? (pin.state ? Colors.green : Colors.grey)
                          : Colors.blue,
                    ),
                    title: Text(pin.name),
                    subtitle: Text(_formatPinValue(pin)),
                    onTap: pin.type == "OUTPUT" ? () => _togglePin(pin) : null,
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFromString(String name) {
    switch (name) {
      case 'device_hub': return Icons.device_hub;
      case 'bolt': return Icons.bolt;
      case 'power': return Icons.power;
      case 'water_drop': return Icons.water_drop;
      case 'water_pump': return Symbols.water_pump;
      case 'pool': return Symbols.pool;
      case 'fan': return Symbols.mode_fan;
      case 'motor': return Symbols.electric_meter;
      case 'ac_unit': return Icons.ac_unit;
      case 'lightbulb': return Icons.lightbulb;
      case 'flash_on': return Icons.flash_on;
      case 'heating': return Symbols.heat;
      default: return Icons.device_hub;
    }
  }
}
