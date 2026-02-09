import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/esp_device.dart';
import '../models/esp_pin.dart';
import 'package:logger/logger.dart';  

final logger = Logger();

class DBHelper {
  static Database? _db;

  // ----------------- Initialisation DB -----------------
  static Future<Database> getDb() async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      join(await getDatabasesPath(), 'domotique.db'),
      version: 3, // version 3 pour ajouter type, sensorType et value
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE devices(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            localIP TEXT,
            publicIP TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE pins(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            pin TEXT,
            state INTEGER,
            value REAL,
            type TEXT DEFAULT 'OUTPUT',
            sensorType TEXT,
            iconName TEXT DEFAULT 'device_hub',
            deviceId INTEGER,
            FOREIGN KEY(deviceId) REFERENCES devices(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE wifi(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ssid TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Ajouter table wifi si elle n'existe pas
          await db.execute('''
            CREATE TABLE wifi(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ssid TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          // Ajouter les colonnes type, sensorType, value
          await db.execute('ALTER TABLE pins ADD COLUMN type TEXT DEFAULT "OUTPUT"');
          await db.execute('ALTER TABLE pins ADD COLUMN sensorType TEXT');
          await db.execute('ALTER TABLE pins ADD COLUMN value REAL');
        }
      },
    );
    return _db!;
  }

  // ----------------- Devices -----------------
  static Future<int> insertDevice(ESPDevice device) async {
    final db = await getDb();
    return await db.insert('devices', {
      'name': device.name,
      'localIP': device.localIP,
      'publicIP': device.publicIP,
    });
  }

  static Future<List<Map<String, dynamic>>> getDevices() async {
    final db = await getDb();
    return await db.query('devices');
  }

  // ----------------- Pins -----------------
 static Future<int> insertPin(ESPPin pin, int deviceId) async {
  final db = await getDb();
  print('>>> insertPin called for deviceId=$deviceId, pin=${pin.name}, type=${pin.type}, sensorType=${pin.sensorType}');
  return await db.insert('pins', {
    'name': pin.name,
    'pin': pin.pin,
    'state': pin.state ? 1 : 0,
    'value': pin.value,
    'type': pin.type,
    'sensorType': pin.sensorType,
    'iconName': pin.iconName,
    'deviceId': deviceId,
  });
}


  static Future<List<Map<String, dynamic>>> getPins(int deviceId) async {
    final db = await getDb();
    return await db.query(
      'pins',
      where: 'deviceId=?',
      whereArgs: [deviceId],
    );
  }

  static Future<void> updatePinState(int id, bool state) async {
    final db = await getDb();
    await db.update(
      'pins',
      {'state': state ? 1 : 0},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  static Future<void> updatePin(ESPPin pin, int id) async {
    final db = await getDb();
    await db.update(
      'pins',
      {
        'name': pin.name,
        'pin': pin.pin,
        'state': pin.state == true ? 1 : 0,
        'value': pin.value,
        'type': pin.type,
        'sensorType': pin.sensorType,
        'iconName': pin.iconName,
      },
      where: 'id=?',
      whereArgs: [id],
    );
  }

  // ----------------- Wi-Fi -----------------
  static Future<void> setWifiName(String ssid) async {
    final db = await getDb();

    // On supprime l'ancien ssid pour n'avoir qu'une seule entrée
    await db.delete('wifi');
    await db.insert('wifi', {'ssid': ssid});
  }

  static Future<String?> getWifiName() async {
    final db = await getDb();
    final list = await db.query('wifi', limit: 1);
    if (list.isNotEmpty) return list.first['ssid'] as String;
    return null;
  }
}
