import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class OpenChargeMapService {
  static const String baseUrl = "https://api.openchargemap.io/v3/poi";

  Future<List<dynamic>> getChargingStations(double latitude, double longitude) async {
    final Uri url = Uri.parse(
        "$baseUrl?output=json&latitude=$latitude&longitude=$longitude&distance=10&distanceunit=KM&key=$API_KEY");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Veri çekme başarısız: ${response.statusCode}");
    }
  }
}