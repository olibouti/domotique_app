import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(); // pour l'initialisation
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings, // correct
    );

    await _notifications.initialize(initSettings);
  }

  static Future<void> show(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id', 'Domotique Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    // Attention : DarwinNotificationDetails et non InitializationSettings
    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails, // correct
    );

    await _notifications.show(0, title, body, notificationDetails);
  }
}
