import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'profile_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Marker> _markers = [];
  LatLng? _userLocation;
  Marker? _nearestMarker;
  String _searchQuery = ''; 
  double _maxDistance = 50; 
  String _chargeTypeFilter = ''; 

  @override
  void initState() {
    super.initState();
    _fetchStations();
    _loadCustomStations();
    _getUserLocation();  
  }

  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _fetchStations() async {
    final url = Uri.parse(
      'https://api.openchargemap.io/v3/poi/?output=json&countrycode=TR&latitude=40.3522&longitude=27.9706&distance=$_maxDistance&distanceunit=KM',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Marker> loadedMarkers = [];
      Marker? nearestMarker;
      double nearestDistance = double.infinity;

      for (var station in data) {
        final lat = station['AddressInfo']['Latitude'];
        final lon = station['AddressInfo']['Longitude'];
        final title = station['AddressInfo']['Title'];
        final stationPosition = LatLng(lat, lon);

        if (_searchQuery.isNotEmpty && !title.toLowerCase().contains(_searchQuery.toLowerCase())) {
          continue;
        }

        if (_chargeTypeFilter.isNotEmpty &&
            !station['Connections']
                .any((connection) => connection['ConnectionType']['Title'].toLowerCase().contains(_chargeTypeFilter.toLowerCase()))) {
          continue;
        }

        if (_userLocation != null) {
          double distance = _calculateDistance(_userLocation!, stationPosition);
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestMarker = Marker(
              width: 80.0,
              height: 80.0,
              point: stationPosition,
              builder: (ctx) => Icon(
                Icons.ev_station,
                color: Colors.red, 
                size: 40,
              ),
            );
          }
        }

        loadedMarkers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: stationPosition,
            builder: (ctx) => Icon(
              Icons.ev_station,
              color: Colors.green, 
              size: 40,
            ),
          ),
        );
      }

      if (nearestMarker != null) {
        loadedMarkers.add(nearestMarker);
      }

      setState(() {
        _markers.addAll(loadedMarkers);
        _nearestMarker = nearestMarker;
      });
    } else {
      print('API error: ${response.statusCode}');
    }
  }

  double _calculateDistance(LatLng userLocation, LatLng stationLocation) {
    final double distanceInMeters = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      stationLocation.latitude,
      stationLocation.longitude,
    );
    return distanceInMeters;  
  }

  Future<void> _loadCustomStations() async {
    final snapshot = await FirebaseFirestore.instance.collection('customStations').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final title = data['title'];
      final lat = data['latitude'];
      final lon = data['longitude'];

      setState(() {
        _markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(lat, lon),
            builder: (ctx) => GestureDetector(
              onTap: () => _showReservationDialog(title),
              child: Icon(Icons.ev_station, color: Colors.orange, size: 40),
            ),
          ),
        );
      });
    }
  }

  Future<void> _saveReservation(String stationTitle, DateTime selectedDateTime) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance.collection('reservations').add({
    'userId': user.uid,
    'stationTitle': stationTitle,
    'timestamp': Timestamp.now(),
    'reservationTime': Timestamp.fromDate(selectedDateTime), // Yeni eklenen alan
  });
}

  Future<String?> _getTextInput(String hint) async {
    String input = '';
    return await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(hint),
          content: TextField(
            onChanged: (value) => input = value,
            decoration: InputDecoration(hintText: "örn: Evdeki Şarj Noktam"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("İptal")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, input), child: Text("Kaydet")),
          ],
        );
      },
    );
  }

  void _showReservationDialog(String stationTitle) async {
  DateTime? selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(Duration(days: 30)),
  );

  if (selectedDate == null) return;

  TimeOfDay? selectedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (selectedTime == null) return;

  final selectedDateTime = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    selectedTime.hour,
    selectedTime.minute,
  );

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text("Rezervasyon"),
        content: Text(
          "$stationTitle istasyonuna şu tarih için rezervasyon yapmak istiyor musunuz?\n\n${selectedDateTime.toLocal()}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveReservation(stationTitle, selectedDateTime);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Rezervasyon gönderildi."),
              ));
            },
            child: Text("Evet"),
          ),
        ],
      );
    },
  );
}

  Future<void> _addCustomStation(LatLng point) async {
    String? title = await _getTextInput("İstasyon Başlığı Gir:");
    if (title == null || title.isEmpty) return;

    FirebaseFirestore.instance.collection('customStations').add({
      'title': title,
      'latitude': point.latitude,
      'longitude': point.longitude,
    });

    setState(() {
      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: point,
          builder: (ctx) => GestureDetector(
            onTap: () => _showReservationDialog(title),
            child: Icon(Icons.ev_station, color: Colors.orange, size: 40),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Harita"),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _fetchStations(); 
              },
              decoration: InputDecoration(
                hintText: 'İstasyon Ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          DropdownButton<String>(
            value: _chargeTypeFilter,
            onChanged: (value) {
              setState(() {
                _chargeTypeFilter = value!;
              });
              _fetchStations(); 
            },
            items: <String>['', 'AC', 'DC', 'Hızlı Şarj'].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _userLocation ?? LatLng(40.3522, 27.9706),
                zoom: 13.0,
                onTap: (tapPosition, point) => _addCustomStation(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}