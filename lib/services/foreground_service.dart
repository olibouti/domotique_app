import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logger/logger.dart';

import '../models/esp_device.dart';
import '../services/esp_service.dart';
import '../services/notification_service.dart';
import '../services/db_helper.dart';

final logger = Logger();

/// -------------------------------
/// SERVICE FOREGROUND (UI)
/// -------------------------------
class ESPForegroundService {
  static final ESPForegroundService _instance =
      ESPForegroundService._internal();
  factory ESPForegroundService() => _instance;
  ESPForegroundService._internal();

  Future<void> start({int intervalSeconds = 10}) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'esp_monitoring',
        channelName: 'ESP Monitoring',
        channelDescription: 'Surveillance des ESP',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction:
            ForegroundTaskEventAction.repeat(intervalSeconds * 1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
      ),
    );

    await FlutterForegroundTask.startService(
      notificationTitle: 'Monitoring ESP',
      notificationText: 'Surveillance en cours',
      callback: startCallback,
    );

    FlutterForegroundTask.initCommunicationPort();
  }

  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  /// À appeler APRÈS ajout/suppression d’un device
  void reloadDevices() {
    FlutterForegroundTask.sendDataToTask({
      'action': 'reload_devices',
    });
  }
}

/// -------------------------------
/// CALLBACK ISOLATE
/// -------------------------------
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ESPTaskHandler());
}

/// -------------------------------
/// TASK HANDLER (SERVICE)
/// -------------------------------
class ESPTaskHandler extends TaskHandler {
  final List<ESPDevice> _devices = [];
  final Map<int, bool> _lastStates = {};

  /// Chargement initial
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // logger.i('Foreground service started');

    await _loadDevicesFromDb();
  }

  /// Tick périodique
  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    if (_devices.isEmpty) return;

    for (final device in _devices) {
      final espService = ESPService(device: device);
      bool connected = false;
      // logger.i('device name : ${device.name}');

      try {
        connected = await espService.checkConnection();
        // logger.i('état : $connected');
      } catch (e) {
        logger.e('Check failed for ${device.name}: $e');
      }

      final last = _lastStates[device.id];

      if (last == null || last != connected) {
        _lastStates[device.id!] = connected;

        await NotificationService().show(
          connected ? 'ESP Connecté' : 'ESP Déconnecté',
          '${device.name} est ${connected ? "en ligne" : "hors ligne"}',
        );

        FlutterForegroundTask.sendDataToMain({
          'device': device.name,
          'connected': connected,
        });

        // logger.i('${device.name} state changed: $connected');
      }
    }
  }

  /// Réception des ordres UI
  @override
  Future<void> onReceiveData(Object data) async {
    if (data is Map && data['action'] == 'reload_devices') {
      // logger.i('Reload devices requested');
      await _loadDevicesFromDb();
    }
  }

  /// Nettoyage
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // logger.i('Foreground service stopped');
  }

  /// -------------------------------
  /// DB
  /// -------------------------------
  Future<void> _loadDevicesFromDb() async {
    final rows = await DBHelper.getDevices();

    _devices
      ..clear()
      ..addAll(
        rows.map(
          (row) => ESPDevice(
            id: row['id'],
            name: row['name'],
            localIP: row['localIP'],
            publicIP: row['publicIP'],
          ),
        ),
      );

    _lastStates.clear(); // important

    // logger.i('Devices loaded: ${_devices.length}');
  }
}
