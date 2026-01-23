import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class NetworkService {
  static Future<bool> isLocalNetwork() async {
    final result = await Connectivity().checkConnectivity();
    logger.i('result : $result');
    return result == ConnectivityResult.wifi;
  }
}
