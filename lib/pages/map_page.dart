import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';  
import '../services/api_service.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<dynamic> chargingStations = [];
  Position? _currentPosition;  

  late MapController mapController;  

  @override
  void initState() {
    super.initState();
    fetchChargingStations();
    _getCurrentLocation();  
    mapController = MapController(); 
  }

  Future<void> fetchChargingStations() async {
    try {
      var stations = await OpenChargeMapService().getChargingStations(40.9826, 29.0322);
      setState(() {
        chargingStations = stations;
      });
    } catch (e) {
      print("Hata: $e");
    }
  }

  
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Konum servisleri kapalı.");
      return;
    }


    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Konum izni reddedildi.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Konum izni kalıcı olarak reddedildi.");
      return;
    }


    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;  
    });
  }

  void _updateLocation() async {
    Position newPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    setState(() {
      _currentPosition = newPosition; 
    });

    mapController.move(
      LatLng(newPosition.latitude, newPosition.longitude),  
      14.0,  
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Şarj İstasyonları Haritası")),
      body: _currentPosition == null  
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: mapController,  
              options: MapOptions(
                center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),  
                zoom: 12,
                onPositionChanged: (MapPosition position, bool hasGesture) {
                  if (hasGesture) {
                    _updateLocation();
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: chargingStations.map((station) {
                    return Marker(
                      point: LatLng(
                        station['AddressInfo']['Latitude'],
                        station['AddressInfo']['Longitude'],
                      ),
                      width: 40,
                      height: 40,
                      builder: (context) => Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 30,
                      ),
                    );
                  }).toList(),
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        width: 40,
                        height: 40,
                        builder: (context) => Icon(
                          Icons.person_pin,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}