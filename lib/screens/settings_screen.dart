import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../services/db_helper.dart';
import '../models/esp_device.dart';
import '../models/esp_pin.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, dynamic>> devices = [];
  final TextEditingController wifiController = TextEditingController();

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
              decoration: const InputDecoration(labelText: "IP locale"),
              onChanged: (value) => localIP = value,
            ),
            TextField(
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
    final pinsData = await DBHelper.getPins(deviceId);
    final List<String> gpioOptions = ['D0','D1','D2','D3','D4','D5','D6','D7','D8'];
    List<ESPPin> pins = pinsData.map((p) => ESPPin(
      name: p['name'],
      pin: p['pin'],
      state: p['state']==1,
      iconName: p['iconName']??'device_hub',
    )).toList();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Gérer les pins"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pins.length,
              itemBuilder: (_, index) {
                final pin = pins[index];
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: TextEditingController(text: pin.name),
                          onChanged: (value) => pin.name = value,
                          decoration: const InputDecoration(labelText: "Nom de la pin"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: DropdownButton<String>(
                          value: pin.pin,
                          isExpanded: true,
                          items: gpioOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (value){if(value!=null)setStateDialog(()=>pin.pin=value);},
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 150,
                        child: DropdownButton<String>(
                          value: pin.iconName,
                          isExpanded: true,
                          items: [
                            'device_hub','bolt','power','water_drop','water_pump','pool','fan','motor','ac_unit','lightbulb','flash_on','heating'
                          ].map((iconStr)=>DropdownMenuItem(
                            value: iconStr,
                            child: Row(children:[Icon(_iconFromString(iconStr)), const SizedBox(width:8), Text(iconStr)]),
                          )).toList(),
                          onChanged: (value){if(value!=null)setStateDialog(()=>pin.iconName=value);},
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: (){setStateDialog(()=>pins.removeAt(index));},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Annuler")),
            TextButton(onPressed: ()async{
              final db = await DBHelper.getDb();
              await db.delete('pins', where:'deviceId=?', whereArgs:[deviceId]);
              for(var pin in pins) await DBHelper.insertPin(pin, deviceId);
              Navigator.pop(context);
              _loadDevices();
            }, child: const Text("Enregistrer")),
            TextButton(onPressed: (){
              setStateDialog(()=>pins.add(ESPPin(name:"Nouvelle pin", pin:"D${pins.length}")));
            }, child: const Text("Ajouter pin")),
          ],
        ),
      ),
    );
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
