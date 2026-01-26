// lib/services/esp_foreground_service.dart
import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logger/logger.dart';
import '../models/esp_device.dart';
import 'esp_service.dart';
import 'notification_service.dart';

final logger = Logger();

/// Singleton pour gérer le service de monitoring
class ESPForegroundService {
  static final ESPForegroundService _instance = ESPForegroundService._internal();
  factory ESPForegroundService() => _instance;
  ESPForegroundService._internal();

  /// Liste des ESP à surveiller
  final List<ESPDevice> devices = [];

  /// Intervalle de vérification en secondes (défaut 10s)
  int intervalSeconds = 10;

  /// Démarre le service foreground
  Future<void> start({int intervalSeconds = 10}) async {
    this.intervalSeconds = intervalSeconds;

    // ⚙️ Initialisation du plugin
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'esp_monitoring',
        channelName: 'ESP Monitoring',
        channelDescription: 'Surveillance des ESP8266',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(intervalSeconds * 1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    // ⚡ Démarrage du service
    await FlutterForegroundTask.startService(
      notificationTitle: 'Monitoring ESP',
      notificationText: 'Surveillance des ESP en cours',
      callback: startCallback,
    );

    // Initialise le port de communication
    FlutterForegroundTask.initCommunicationPort();
  }

  /// Arrête le service
  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}

/// Callback top-level pour le service
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ESPTaskHandler());
}

/// TaskHandler du service foreground
class ESPTaskHandler extends TaskHandler {
  final Map<int, bool> _lastStates = {};

  /// Called when the task is started
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    logger.i('Foreground service started at $timestamp');
  }

  /// Called based on the eventAction set in ForegroundTaskOptions
  @override
  void onRepeatEvent(DateTime timestamp) async {
    final devices = ESPForegroundService().devices;


    for (var device in devices) {
      final espService = ESPService(device: device);
      bool connected = false;

      try {
        connected = await espService.checkConnection();
      } catch (e) {
        logger.e('Error checking ${device.name}: $e');
      }

      final last = _lastStates[device.hashCode];

      if (last == null || last != connected) {
        _lastStates[device.hashCode] = connected;

        // ⚡ Notification
        await NotificationService().show(
          connected ? "ESP Connecté" : "ESP Déconnecté",
          "${device.name} est ${connected ? "en ligne" : "hors ligne"}",
        );

        // ⚡ Envoi de données vers l'UI
        FlutterForegroundTask.sendDataToMain({
          'device': device.name,
          'connected': connected,
        });

        logger.i('${device.name} state changed: $connected');
      }
    }
  }

  /// Called when the task is destroyed
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    logger.i('Foreground service stopped at $timestamp (timeout: $isTimeout)');
  }

  /// Called when data is sent using `FlutterForegroundTask.sendDataToTask`
  @override
  void onReceiveData(Object data) {
    logger.i('onReceiveData: $data');
  }

  /// Notification button pressed
  @override
  void onNotificationButtonPressed(String id) {
    logger.i('Notification button pressed: $id');
  }

  /// Notification itself pressed
  @override
  void onNotificationPressed() {
    logger.i('Notification pressed');
  }

  /// Notification dismissed
  @override
  void onNotificationDismissed() {
    logger.i('Notification dismissed');
  }
}
