import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReservationHistoryPage extends StatefulWidget {
  @override
  _ReservationHistoryPageState createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Rezervasyon Geçmişi")),
        body: Center(
          child: Text("Lütfen giriş yapınız."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Rezervasyon Geçmişi")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final reservations = snapshot.data!.docs;

          if (reservations.isEmpty) {
            return Center(child: Text("Rezervasyon bulunamadı."));
          }

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final data = reservations[index].data() as Map<String, dynamic>;
              final reservationId = reservations[index].id;
              final stationTitle = data['stationTitle'] ?? 'İstasyon';
              final time = (data['reservationTime'] as Timestamp?)?.toDate();
              final price = data['pricePerHour'] ?? 0;
              final duration = data['duration'] ?? 1;
              final totalAmount = data['totalAmount'] ?? price * duration;

              return ListTile(
                title: Text(stationTitle),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(time != null
                        ? "Zaman: ${DateFormat('dd MMM yyyy - HH:mm').format(time)}"
                        : "Tarih belirtilmemiş"),
                    Text("Fiyat/saat: ₺${price.toStringAsFixed(2)}"),
                    Text("Süre: ${duration.toString()} saat"),
                    Text("Toplam: ₺${totalAmount.toStringAsFixed(2)}"),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'iptal') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Rezervasyonu iptal et?'),
                          content: Text('Bu işlemi yapmak istediğinizden emin misiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Hayır'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Evet'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('reservations')
                            .doc(reservationId)
                            .delete();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Rezervasyon iptal edildi.")),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'iptal',
                      child: Text('İptal Et'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}