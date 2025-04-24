class ChargeStation {
  final int id;
  final String title;
  final double latitude;
  final double longitude;

  ChargeStation({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  factory ChargeStation.fromJson(Map<String, dynamic> json) {
    return ChargeStation(
      id: json['ID'],
      title: json['AddressInfo']['Title'],
      latitude: json['AddressInfo']['Latitude'],
      longitude: json['AddressInfo']['Longitude'],
    );
  }
}