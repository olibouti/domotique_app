class ESPPin {
  String name;
  String pin;
  bool state;
  String iconName;

  ESPPin({
    required this.name,
    required this.pin,
    this.state = false,
    this.iconName = 'device_hub',
  });
}
