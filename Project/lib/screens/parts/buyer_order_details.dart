import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../product_verification_page.dart';

class OrderDetailsPage extends StatelessWidget {
  final QueryDocumentSnapshot orderDoc;

  OrderDetailsPage({required this.orderDoc});

  @override
  Widget build(BuildContext context) {
    final String transactionHash = orderDoc['transaction_hash'] ?? 'dummy-hash';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // QR Code Section
          Container(
            color: Colors.deepPurple.shade50,
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  'Scan QR Code for Transaction Info',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                SizedBox(height: 10),
                QrImageView(
                  data: transactionHash,
                  version: QrVersions.auto,
                  size: 200,
                  gapless: false,
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display product images and details
                  for (var product in orderDoc['products'] as List<dynamic>)
                    Card(
                      elevation: 3,
                      margin: EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                product['image_url'] ?? 'https://placehold.co/100x100',
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 10),
                            // Product Information
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['title'] ?? 'Unknown Product',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  Text('Quantity: ${product['quantity'] ?? 0}'),
                                  Text(
                                    'Price: \$${(double.tryParse(product['price'].toString()) ?? 0.0).toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Verify Authenticity Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to VerificationPage with the transaction hash
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerificationPage(transactionHash: transactionHash),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Center(
                child: Text(
                  'Verify Authenticity',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
