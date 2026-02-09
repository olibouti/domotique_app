class ESPPin {
  int? id;
  String name;
  String pin;
  bool state;         // pour les sorties ON/OFF
  String iconName;
  String type;        // "OUTPUT" ou "SENSOR"
  String? sensorType; // ex: "temperature", "distance"
  double? value;      // valeur mesurée pour les capteurs

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

  /// Méthode pratique pour créer une ESPPin depuis la DB
  factory ESPPin.fromDb(Map<String, dynamic> map) {
    return ESPPin(
      name: map['name'],
      pin: map['pin'],
      state: map['state'] == 1,
      iconName: map['iconName'] ?? 'device_hub',
      type: map['type'] ?? 'OUTPUT',
      sensorType: map['sensorType'],
      value: map['value'] != null ? (map['value'] as num).toDouble() : null,
    );
  }

  /// Convertir en Map pour l'insertion / mise à jour DB
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
}
