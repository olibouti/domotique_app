import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';
import 'services/db_helper.dart';
import 'services/notification_service.dart';
import 'services/esp_service.dart';
import 'services/network_service.dart';
import 'models/esp_device.dart';
import 'models/esp_pin.dart';
import 'services/foreground_service.dart';



void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Charger tous les ESP de la BDD
    final devices = await DBHelper.getDevices();
    for (var d in devices) {
      final deviceId = d['id'];
      final pinsData = await DBHelper.getPins(deviceId);
      final pins = pinsData.map((p) => ESPPin(
        name: p['name'],
        pin: p['pin'],
        state: p['state'] == 1,
      )).toList();

      final espDevice = ESPDevice(
        name: d['name'],
        localIP: d['localIP'],
        publicIP: d['publicIP'],
        pins: pins,
      );

      final espService = ESPService(device: espDevice);
      try {
        final status = await espService.fetchLedStatus();
        for (var pin in espDevice.pins) {
          final oldState = pin.state;
          pin.state = status[pin.pin] ?? false;
          if (oldState != pin.state) {
            await DBHelper.updatePinState(pins.indexOf(pin)+1, pin.state);
            NotificationService().show(pin.name, "Nouvel état : ${pin.state ? "ON" : "OFF"}");
          }
        }
      } catch (e) {
        NotificationService().show("Erreur", "Impossible de synchroniser ${espDevice.name}");
      }
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialiser notifications
  await NotificationService().initNotifications();

  // Initialiser workmanager
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Planifier la tâche périodique toutes les 15 minutes
  Workmanager().registerPeriodicTask(
    "syncPinsTask",
    "syncPins",
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(seconds: 10),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );

    await ESPForegroundService().start();


  runApp(const MyApp());
}
