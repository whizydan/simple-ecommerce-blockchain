import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../order_details_page.dart';

class AdminOrdersPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('cart')
            .orderBy('created_at', descending: false)
            .where('status', isEqualTo: 'order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No orders found'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              num totalProducts = 0;
              for(var product in order['products']){
                totalProducts += product['quantity'];
              }
              var orderData = order.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text('Order ID: ${order.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Status: ${orderData['payment_status']}'),
                      Text('Delivery Status: ${orderData['status_delivery']}'),
                      Text('Total Products: ${totalProducts}'),
                      Text(
                        'Date: ${formatFirebaseTimestamp(orderData['created_at'])}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailsPage(orderId: order.id, orderData: orderData),
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
