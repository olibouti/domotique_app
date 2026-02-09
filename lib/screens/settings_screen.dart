import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../services/db_helper.dart';
import '../models/esp_device.dart';
import '../models/esp_pin.dart';
import 'pinSetting_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, dynamic>> devices = [];
  final TextEditingController wifiController = TextEditingController(text: "Livebox-9E9C");
  TextEditingController localIpController = TextEditingController(text: "http://192.168.1."); 
  TextEditingController publicIpController = TextEditingController(text: "https://irrigation-control.educpop.net"); 


  @override
void dispose() {
  localIpController.dispose(); // toujours nettoyer le controller
  publicIpController.dispose(); // toujours nettoyer le controller
  wifiController.dispose(); // toujours nettoyer le controller
  super.dispose();
}


  @override
  void initState() {
    super.initState();
    _loadDevices();
    _loadWifiName();
  }

  Future<void> _loadDevices() async {
    final list = await DBHelper.getDevices();
    setState(() {
      devices = list;
    });
  }

  Future<void> _loadWifiName() async {
    final ssid = await DBHelper.getWifiName();
    setState(() {
      wifiController.text = ssid ?? '';
    });
  }

  Future<void> _saveWifiName() async {
    final ssid = wifiController.text.trim();
    if (ssid.isNotEmpty) {
      await DBHelper.setWifiName(ssid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("SSID enregistré")),
      );
    }
  }

  // ----------------- Ajouter un ESP -----------------
  Future<void> _addDevice() async {
    String name = "";
    String localIP = "";
    String publicIP = "";

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un ESP"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Nom"),
              onChanged: (value) => name = value,
            ),
            TextField(
              controller: localIpController,
              decoration: const InputDecoration(labelText: "IP locale"),
              onChanged: (value) => localIP = value,
            ),
            TextField(
              controller: publicIpController,
              decoration: const InputDecoration(labelText: "IP publique"),
              onChanged: (value) => publicIP = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              if (name.isNotEmpty && localIP.isNotEmpty) {
                final device = ESPDevice(
                  name: name,
                  localIP: localIP,
                  publicIP: publicIP,
                  pins: [],
                );
                final id = await DBHelper.insertDevice(device);

                // Ajouter 3 pins par défaut
                await DBHelper.insertPin(
                  ESPPin(name: "Électrovanne 1", pin: "D0"),
                  id,
                );
                await DBHelper.insertPin(
                  ESPPin(name: "Électrovanne 2", pin: "D1"),
                  id,
                );
                await DBHelper.insertPin(
                  ESPPin(name: "Pompe", pin: "D2"),
                  id,
                );

                Navigator.pop(context);
                _loadDevices();
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  // ----------------- Modifier un ESP -----------------
  Future<void> _editDevice(Map<String, dynamic> device) async {
    String name = device['name'];
    String localIP = device['localIP'];
    String publicIP = device['publicIP'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier ESP"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Nom"),
              controller: TextEditingController(text: name),
              onChanged: (value) => name = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "IP locale"),
              controller: TextEditingController(text: localIP),
              onChanged: (value) => localIP = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "IP publique"),
              controller: TextEditingController(text: publicIP),
              onChanged: (value) => publicIP = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              if (name.isNotEmpty && localIP.isNotEmpty) {
                final db = await DBHelper.getDb();
                await db.update(
                  'devices',
                  {'name': name, 'localIP': localIP, 'publicIP': publicIP},
                  where: 'id=?',
                  whereArgs: [device['id']],
                );
                Navigator.pop(context);
                _loadDevices();
              }
            },
            child: const Text("Enregistrer"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editPins(device['id']);
            },
            child: const Text("Gérer les pins"),
          ),
        ],
      ),
    );
  }

  // ----------------- Supprimer un ESP -----------------
  Future<void> _deleteDevice(int id) async {
    final db = await DBHelper.getDb();
    await db.delete('pins', where: 'deviceId=?', whereArgs: [id]);
    await db.delete('devices', where: 'id=?', whereArgs: [id]);
    _loadDevices();
  }

  // ----------------- Gérer les pins -----------------
Future<void> _editPins(int deviceId) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PinsSettingsScreen(deviceId: deviceId),
    ),
  );

  if (result == true) {
    _loadDevices();
  }
}


  // ----------------- Build -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres"), backgroundColor: Colors.blueAccent),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDevice,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ⚡ Champ Wi-Fi
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: wifiController,
                      decoration: const InputDecoration(labelText: "Nom du réseau Wi-Fi"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.green),
                    onPressed: _saveWifiName,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ⚡ Liste des devices
          ...devices.map((device) => Card(
            child: ListTile(
              title: Text(device['name']),
              subtitle: Text("Local: ${device['localIP']}\nPublic: ${device['publicIP']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: ()=>_editDevice(device)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: ()=>_deleteDevice(device['id'])),
                  IconButton(icon: const Icon(Icons.tune, color: Colors.blue), onPressed: ()=>_editPins(device['id'])),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  IconData _iconFromString(String name){
    switch(name){
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
