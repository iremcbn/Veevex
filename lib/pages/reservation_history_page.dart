import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationHistoryPage extends StatelessWidget {
  const ReservationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Kullanıcı girişi bulunamadı.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rezervasyon Geçmişi"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("Henüz rezervasyon bulunmuyor."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final station = data['stationTitle'] ?? 'Bilinmeyen İstasyon';
              final timestamp = (data['timestamp'] as Timestamp).toDate();

              return ListTile(
                leading: const Icon(Icons.ev_station),
                title: Text(station),
                subtitle: Text(timestamp.toString()),
              );
            },
          );
        },
      ),
    );
  }
}