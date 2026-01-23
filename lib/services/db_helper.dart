import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/esp_device.dart';
import '../models/esp_pin.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> getDb() async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      join(await getDatabasesPath(), 'domotique.db'),
      version: 1,
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
            iconName TEXT DEFAULT 'device_hub',
            deviceId INTEGER,
            FOREIGN KEY(deviceId) REFERENCES devices(id)
          )
        ''');

      },
       onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // ⚡️ Ajouter la colonne iconName si elle n'existe pas
          await db.execute(
              "ALTER TABLE pins ADD COLUMN iconName TEXT DEFAULT 'device_hub'");
        }
      },
    );
    return _db!;
  }

  // Devices
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

  // Pins
  static Future<int> insertPin(ESPPin pin, int deviceId) async {
    final db = await getDb();
    return await db.insert('pins', {
      'name': pin.name,
      'pin': pin.pin,
      'state': pin.state ? 1 : 0,
      'deviceId': deviceId,
      'iconName': pin.iconName,
    });
  }

  static Future<List<Map<String, dynamic>>> getPins(int deviceId) async {
    final db = await getDb();
    return await db.query('pins', where: 'deviceId=?', whereArgs: [deviceId]);
  }

  static Future<void> updatePinState(int id, bool state) async {
    final db = await getDb();
    await db.update('pins', {'state': state ? 1 : 0}, where: 'id=?', whereArgs: [id]);
  }
}
