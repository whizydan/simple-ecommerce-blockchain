import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'buyer_order_details.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Stream<QuerySnapshot> _ordersStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String formatFirebaseTimestamp(dynamic timestamp) {
  if (timestamp == null) return "Invalid Date";

  DateTime dateTime;

  // Check if the input is a Firebase Timestamp
  if (timestamp is Timestamp) {
    dateTime = timestamp.toDate();
  } 
  // Check if the input is already a DateTime
  else if (timestamp is DateTime) {
    dateTime = timestamp;
  } 
  // Check if the input is a valid string that can be parsed into a DateTime
  else if (timestamp is String) {
    try {
      dateTime = DateTime.parse(timestamp);
    } catch (e) {
      return "Invalid Date Format";
    }
  } 
  // If the input is not in a recognized format
  else {
    return "Unsupported Type";
  }

  // Format the DateTime into a readable string
  return DateFormat('dd-MM-yyyy HH:mm:ss').format(dateTime);
}

  @override
  void initState() {
    super.initState();
    _ordersStream = FirebaseFirestore.instance
        .collection('cart')
        .orderBy('created_at', descending: false)
        .where('status', isEqualTo: 'order')
        .where('user_id', isEqualTo: _auth.currentUser!.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No orders found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var orderDoc = snapshot.data!.docs[index];
              var paymentStatus = orderDoc['payment_status'];
              var deliveryStatus = orderDoc['status_delivery'];
              var dateTime = orderDoc['created_at'];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.shopping_bag),
                  title: Text('Order #${orderDoc.id.substring(0, 6).toUpperCase()}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment: ${paymentStatus.toUpperCase()}',
                        style: TextStyle(
                          color: paymentStatus == 'paid' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Delivery: ${deliveryStatus.toUpperCase()}',
                        style: TextStyle(
                          color: deliveryStatus == 'delivered' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Date: ${formatFirebaseTimestamp(dateTime)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to the OrderDetailsPage and pass order data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsPage(orderDoc: orderDoc),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}