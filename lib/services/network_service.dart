import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

final logger = Logger();

class NetworkService {
  /// Demande la permission de localisation (nécessaire pour récupérer le SSID)
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  /// Renvoie true si connecté à un Wi-Fi
  static Future<bool> isLocalNetwork() async {
    final result = await Connectivity().checkConnectivity();
    logger.i('Connectivity result: $result');
    return result == ConnectivityResult.wifi;
  }

  /// Renvoie le nom du SSID si connecté à un Wi-Fi, sinon null
  static Future<String?> getWifiName() async {
    try {
      final info = NetworkInfo();
      // Vérifie la permission
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        logger.w("Permission localisation non accordée");
        return null;
      }

      final ssid = await info.getWifiName();
      logger.i('SSID détecté: $ssid');
      return ssid;
    } catch (e) {
      logger.w('Impossible de récupérer le SSID: $e');
      return null;
    }
  }
}
