import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  final LatLng _initialPosition = LatLng(35.6896, -0.6412); 
  final Set<Marker> _markers = {
    Marker(
      markerId: MarkerId('1'),
      position: LatLng(35.6896, -0.6412),
      infoWindow: InfoWindow(title: 'Şarj İstasyonu 1'),
    ),
    Marker(
      markerId: MarkerId('2'),
      position: LatLng(36.7538, 3.042),
      infoWindow: InfoWindow(title: 'Şarj İstasyonu 2'),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Şarj İstasyonları Haritası'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 7.0,
            ),
            markers: _markers,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Konum Ara...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Ödemeler'),
          BottomNavigationBarItem(icon: Icon(Icons.add_location), label: 'İstasyon Ekle'),
        ],
        onTap: (index) {
          
        },
     ) ,
    );
  }
}