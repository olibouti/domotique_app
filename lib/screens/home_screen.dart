import 'package:flutter/material.dart';
import '../models/esp_device.dart';
import '../models/esp_pin.dart';
import '../services/db_helper.dart';
import '../services/esp_service.dart';
import 'deviceControl_screen.dart';
import 'settings_screen.dart';
import 'package:logger/logger.dart';
import '../services/network_service.dart';

final logger = Logger();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ESPDevice> devices = [];
  Map<int, bool> deviceStatus = {};
  Map<int, Map<String, bool>> pinsStatus = {};
  bool loading = true;
  String connectionMode = '';

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _detectConnectionMode() async {
    final rawSsid = await NetworkService.getWifiName();
    final savedSsid = await DBHelper.getWifiName();
    final currentSsid = rawSsid?.replaceAll('"', '').replaceAll("'", "").trim();

    if (currentSsid != null &&
        savedSsid != null &&
        currentSsid.toLowerCase() == savedSsid.toLowerCase()) {
      setState(() => connectionMode = "local");
    } else {
      setState(() => connectionMode = "externe");
    }
  }

  Future<void> _loadDevices() async {
    setState(() => loading = true);
    await _detectConnectionMode();

    final dbDevices = await DBHelper.getDevices();

    if (dbDevices.isEmpty) {
      setState(() {
        devices = [];
        deviceStatus = {};
        pinsStatus = {};
        loading = false;
      });
      return;
    }

    List<ESPDevice> loadedDevices = [];

    for (var d in dbDevices) {
      final pinsData = await DBHelper.getPins(d['id']);
      final pins = pinsData.map((p) => ESPPin.fromDb(p)).toList();

      loadedDevices.add(
        ESPDevice(
          name: d['name'],
          localIP: d['localIP'],
          publicIP: d['publicIP'],
          pins: pins,
        ),
      );
    }

    Map<int, bool> statusMap = {};
    Map<int, Map<String, bool>> pinsMap = {};

    // Vérification de la connexion et récupération du statut des pins
    await Future.wait(
      loadedDevices.map((device) async {
        final espService = ESPService(device: device);
        bool connected = await espService.checkConnection();
        Map<String, bool> pins = {};
        if (connected) {
          final rawPins = await espService.fetchLedStatus();
          pins = {for (var p in rawPins) p.pin: p.state};
        }
        statusMap[device.hashCode] = connected;
        pinsMap[device.hashCode] = pins;
      }),
    );

    setState(() {
      devices = loadedDevices;
      deviceStatus = statusMap;
      pinsStatus = pinsMap;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          "Mes Appareils Connectés",
          style: TextStyle(color: Colors.white),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/ic_launcher.png', width: 32, height: 32),
        ),
      ),
      body: Stack(
        children: [
          // 🌄 Image de fond
          Positioned.fill(
            child: Image.asset('assets/ic_launcher.png', fit: BoxFit.contain),
          ),

          // 💡 Liste des devices
          loading
              ? const Center(child: CircularProgressIndicator())
              : devices.isEmpty
              ? const Center(
                  child: Text(
                    "Aucun device enregistré.\nAjoutez-en depuis les paramètres.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDevices,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 60,
                    ),
                    itemCount: devices.length,
                    itemBuilder: (_, index) {
                      final device = devices[index];
                      final connected = deviceStatus[device.hashCode] ?? false;
                      final pins = pinsStatus[device.hashCode] ?? {};
                      final pinsOn = pins.values.where((v) => v).length;

                      return Card(
                        color: Colors.white.withValues(alpha: 0.8),
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            connected ? Icons.wifi : Icons.wifi_off,
                            color: connected ? Colors.green : Colors.red,
                            size: 40,
                          ),
                          title: Text(
                            device.name,
                            style: const TextStyle(fontSize: 20),
                          ),
                          subtitle: Text(
                            connected
                                ? "$pinsOn/${device.pins.length} pins allumées"
                                : "Déconnecté",
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: connected
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DeviceControlScreen(device: device),
                                    ),
                                  ).then((_) => _loadDevices());
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                ),

          // 📌 Texte collé tout en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white.withOpacity(
                0.7,
              ), // optionnel : fond léger pour lisibilité
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                connectionMode.isNotEmpty
                    ? "Connecté au réseau $connectionMode"
                    : "Connexion : inconnue",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      connectionMode == "local" || connectionMode == "externe"
                      ? const Color.fromARGB(255, 104, 167, 209)
                      : const Color.fromARGB(255, 255, 0, 0),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey[50],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.green),
                    onPressed: _loadDevices,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ).then((_) => _loadDevices());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
