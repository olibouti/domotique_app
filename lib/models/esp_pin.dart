class ESPPin {
  int? id;
  String name;
  String pin;         // ex: D0, D1...
  bool state;         // pour les sorties ON/OFF
  String iconName;    // icône Material / Symbols
  String type;        // OUTPUT, INPUT_DIGITAL, INPUT_ANALOG, SENSOR_DHT, SENSOR_ULTRASONIC, SENSOR_DS18B20
  String? sensorType; // ex: "DHT22", "HC-SR04", "DS18B20"
  double? value;      // valeur mesurée pour les capteurs, ou double.nan si inaccessible

  ESPPin({
    required this.name,
    required this.pin,
    this.id,
    this.state = false,
    this.iconName = 'device_hub',
    this.type = 'OUTPUT',
    this.sensorType,
    this.value,
  });

  /// Crée un ESPPin depuis la DB en sécurisant les types et valeurs
  factory ESPPin.fromDb(Map<String, dynamic> map) {
    return ESPPin(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Pin',
      pin: map['pin'] as String? ?? 'D0',
      state: (map['state'] ?? 0) == 1,
      iconName: map['iconName'] as String? ?? 'device_hub',
      type: map['type'] as String? ?? 'OUTPUT',
      sensorType: map['sensorType'] as String?,
      value: map['value'] != null
          ? (map['value'] is num
              ? (map['value'] as num).toDouble()
              : double.nan)
          : null,
    );
  }

  /// Convertit en Map pour l'insertion ou mise à jour dans la DB
  Map<String, dynamic> toDbMap({int? deviceId}) {
    return {
      'name': name,
      'pin': pin,
      'state': state ? 1 : 0,
      'iconName': iconName,
      'type': type,
      'sensorType': sensorType,
      'value': value,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }

  /// Indique si c'est un capteur (SENSOR_*)
  bool get isSensor =>
      type == 'SENSOR_DHT' ||
      type == 'SENSOR_ULTRASONIC' ||
      type == 'SENSOR_DS18B20';

  /// Indique si c'est une sortie ON/OFF
  bool get isOutput => type == 'OUTPUT';
}