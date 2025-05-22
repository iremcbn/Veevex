import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'payment_page.dart';
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
    determinePosition().then(() {
      _fetchStations();
      _loadCustomStations();
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Konum servisi kapalıysa kullanıcıyı uyar
      return Future.error('Konum servisi kapalı.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Konum izni reddedildi.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Konum izni kalıcı olarak reddedildi.');
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _fetchStations() async {
    if (_userLocation == null) return;

    final url = Uri.parse(
      'https://api.openchargemap.io/v3/poi/?output=json'
      '&countrycode=TR'
      '&latitude=${_userLocation!.latitude}'
      '&longitude=${_userLocation!.longitude}'
      '&distance=$_maxDistance'
      '&distanceunit=KM'
      '&maxresults=50',
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
        final title = station['AddressInfo']['Title'] ?? 'İsimsiz İstasyon';
        final stationPosition = LatLng(lat, lon);

        if (_searchQuery.isNotEmpty &&
            !title.toLowerCase().contains(_searchQuery.toLowerCase())) {
          continue;
        }

        if (_chargeTypeFilter.isNotEmpty) {
          bool hasType = false;
          for (var connection in station['Connections']) {
            final connType = connection['ConnectionType']['Title'] ?? '';
            if (connType.toLowerCase().contains(_chargeTypeFilter.toLowerCase())) {
              hasType = true;
              break;
            }
          }
          if (!hasType) continue;
        }

        double distance = _calculateDistance(_userLocation!, stationPosition);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestMarker = Marker(
            width: 80.0,
            height: 80.0,
            point: stationPosition,
            builder: (context) => Icon(Icons.ev_station, color: Colors.red, size: 40),
          );
        }

        loadedMarkers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: stationPosition,
            builder: (context) => Icon(Icons.ev_station, color: Colors.green, size: 35),
          ),
        );
      }

      if (nearestMarker != null) {
        loadedMarkers.add(nearestMarker);
      }

      setState(() {
        _markers = loadedMarkers;
        _nearestMarker = nearestMarker;
      });
    } else {
      print('Open Charge Map API hatası: ${response.statusCode}');
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000;
  }

  Future<void> _loadCustomStations() async {
    final snapshot = await FirebaseFirestore.instance.collection('customStations').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final title = data['title'] ?? 'Özel İstasyon';
      final lat = data['latitude'];
      final lon = data['longitude'];
      final price = data['price'] ?? 0;

      setState(() {
        _markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(lat, lon),
            builder: (context) => GestureDetector(
              onTap: () => _showReservationDialog(title, price.toDouble()),
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
      'reservationTime': Timestamp.fromDate(selectedDateTime),
    });
  }

  Future<void> _showReservationDialog(String stationTitle, double price) async {
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

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Rezervasyon Onayı"),
          content: Text(
            "$stationTitle istasyonu için rezervasyon yapılıyor.\n\n"
            "Seçilen tarih ve saat: ${selectedDateTime.toLocal()}\n"
            "Saatlik ücret: ₺$price\n\n"
            "Devam etmek istiyor musunuz?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Evet"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _saveReservation(stationTitle, selectedDateTime);

      final paymentResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            paymentUrl: "https://example.com",
            stationTitle: stationTitle,
            selectedDateTime: selectedDateTime,
            price: price,
          ),
        ),
      );

      if (paymentResult == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ödeme başarılı!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ödeme başarısız veya iptal edildi.")),
        );
      }
    }
  }

  Future<void> _addCustomStation(LatLng point) async {
    String? title = await _showTextInputDialog("İstasyon Başlığı Gir:");
    if (title == null || title.isEmpty) return;

    String? priceInput = await _showTextInputDialog("Saatlik Ücret (TL) Gir:");
    if (priceInput == null || priceInput.isEmpty) return;

    double? price = double.tryParse(priceInput);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Geçerli bir fiyat giriniz.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('customStations').add({
      'title': title,
      'latitude': point.latitude,
      'longitude': point.longitude,
      'price': price,
    });

    setState(() {
      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: point,
          builder: (context) => GestureDetector(
            onTap: () => _showReservationDialog(title, price),
            child: Icon(Icons.ev_station, color: Colors.orange, size: 40),
          ),
        ),
      );
    });
  }

  Future<String?> _showTextInputDialog(String hint) async {
    String input = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(hint),
          content: TextField(
            autofocus: true,
            onChanged: (val) => input = val,
            decoration: InputDecoration(hintText: hint),
            keyboardType: hint.contains("Ücret") ? TextInputType.number : TextInputType.text,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("İptal")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, input), child: Text("Kaydet")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Şarj İstasyonları Haritası"),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'İstasyon Ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
                _fetchStations();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _chargeTypeFilter,
              items: ['', 'AC', 'DC', 'Hızlı Şarj'].map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e.isEmpty ? 'Tümü' : e),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _chargeTypeFilter = val ?? '';
                });
                _fetchStations();
              },
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _userLocation ?? LatLng(40.3522, 27.9706),
                zoom: 13,
                onTap: (tapPosition, point) => _addCustomStation(point),
              ),
              children: [
                TileLayerWidget(
                  options: TileLayerOptions(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                ),
                MarkerLayerWidget(
                  options: MarkerLayerOptions(markers: _markers),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}