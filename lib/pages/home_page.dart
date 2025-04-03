import 'package:flutter/material.dart';
import 'map_page.dart';  

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Şarj İstasyonları")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapPage()),
            );
          },
          child: Text("Haritada Şarj İstasyonlarını Gör"),
        ),
      ),
    );
  }
}