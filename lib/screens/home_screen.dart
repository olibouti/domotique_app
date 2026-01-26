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
    _detectConnectionMode();
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

    List<ESPDevice> loaded = [];

    // Charger les devices depuis la DB
    for (var d in dbDevices) {
      final pinsData = await DBHelper.getPins(d['id']);
      final pins = pinsData
          .map(
            (p) => ESPPin(
              name: p['name'],
              pin: p['pin'],
              state: p['state'] == 1,
              iconName: p['iconName'] ?? 'device_hub',
            ),
          )
          .toList();

      loaded.add(
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

    // Vérification de la connexion et récupération du statut des pins en parallèle
    await Future.wait(
      loaded.map((device) async {
        final espService = ESPService(device: device);
        bool connected = await espService.checkConnection();
        Map<String, bool> pins = {};
        if (connected) {
          final rawPins = await espService.fetchLedStatus();
          pins = rawPins.map((k, v) => MapEntry(k.toString(), v == true));
        }
        statusMap[device.hashCode] = connected;
        pinsMap[device.hashCode] = pins;
      }),
    );

    setState(() {
      devices = loaded;
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : devices.isEmpty
          ? const Center(
              child: Text(
                "Aucun device enregistré.\nAjoutez-en depuis les paramètres.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/ic_launcher.png'), // ton image
                  fit: BoxFit.contain, 
                ),
              ),
              child: Column(
                children: [
                  // Liste des appareils qui prend tout l'espace disponible
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadDevices,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: devices.length,
                        itemBuilder: (_, index) {
                          final device = devices[index];
                          final connected =
                              deviceStatus[device.hashCode] ?? false;
                          final pins = pinsStatus[device.hashCode] ?? {};
                          final pinsOn = pins.values.where((v) => v).length;

                          return Card(
                            elevation: 30,
                            color: Colors.white.withValues(alpha: 0.7),
                            margin: const EdgeInsets.symmetric(vertical: 8),
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
                                          builder: (_) => DeviceControlScreen(
                                            device: device,
                                          ),
                                        ),
                                      ).then((_) => _loadDevices());
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ⚡ Texte au bas de la page, au-dessus du BottomAppBar
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      connectionMode.isNotEmpty
                          ? "Connecté au réseau  $connectionMode"
                          : "Connexion : inconnue",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            connectionMode == "local" ||
                                connectionMode == "externe"
                            ? const Color.fromARGB(255, 104, 167, 209)
                            : const Color.fromARGB(255, 255, 0, 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey[50],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ⚡ Boutons
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
