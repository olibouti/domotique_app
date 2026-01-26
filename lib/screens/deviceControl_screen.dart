import 'package:flutter/material.dart';
import '../models/esp_device.dart';
import '../models/esp_pin.dart';
import '../services/esp_service.dart';
import '../services/db_helper.dart';
import '../services/notification_service.dart';
import 'package:material_symbols_icons/symbols.dart';


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

  @override
  void initState() {
    super.initState();
    device = widget.device;
    espService = ESPService(device: device);
    NotificationService().initNotifications();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => loading = true);
    try {
      final status = await espService.fetchLedStatus();
      setState(() {
        for (var pin in device.pins) {
          pin.state = status[pin.pin] ?? false;
        }
      });
    } catch (e) {
      NotificationService().show(
          "Erreur", "Impossible de récupérer le statut des pins");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _togglePin(ESPPin pin) async {
    try {
      final success = await espService.togglePin(pin.pin, !pin.state);
      if (success) {
        setState(() => pin.state = !pin.state);
        final pinIndex = device.pins.indexOf(pin);
        await DBHelper.updatePinState(pinIndex + 1, pin.state);
      } else {
        NotificationService().show(
            "Erreur", "L'ESP n'a pas répondu pour ${pin.name}");
      }
    } catch (e) {
      NotificationService().show(
          "Erreur", "Impossible de changer l'état de ${pin.name}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.name, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.blueAccent),
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
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      _iconFromString(pin.iconName),
                      size: 40,
                      color: pin.state ? Colors.green : Colors.grey,
                    ),
                    title: Text(pin.name),
                    subtitle: Text(pin.state ? "Allumé" : "Éteint"),
                    onTap: () => _togglePin(pin),
                  ),
                );
              },
            ),
    );
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
        return Symbols.pool; // ✅ IconData, pas Icon widget
      case 'fan':
        return Symbols.mode_fan; // ✅ IconData
      case 'motor':
        return Symbols.electric_meter; // si dispo
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
}
