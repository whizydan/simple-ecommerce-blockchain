import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shopper/utils/crypto.dart';

import '../utils/blockchain_service.dart';

class BuyerCheckoutPage extends StatelessWidget {
  final BlockchainService _blockchainService = BlockchainService();

  Future<void> _initializeBlockchainService() async {
    await _blockchainService.init();
  }

  Future<void> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      print("Storage permission granted!");
    } else if (await Permission.manageExternalStorage.request().isGranted) {
      print("Manage external storage permission granted!");
    } else {
      print("Permission denied!");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;
    String userId = user?.uid ?? '';
    _initializeBlockchainService();
    requestStoragePermission();

    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: _getCartItems(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error fetching cart items'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No items in cart'));
            }

            var cartItems = snapshot.data!;
            double total = _calculateTotal(cartItems);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Orders', style: TextStyle(fontSize: 24)),
                SizedBox(height: 20),
                _orderSummary(cartItems, total),
                SizedBox(height: 30),
                _paymentCard(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _processPayment(context, total);
                  },
                  child: Text('Pay', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getCartItems(String userId) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('cart')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'cart')
        .get();

    List<Map<String, dynamic>> cartItems = [];
    for (var doc in querySnapshot.docs) {
      var cartData = doc.data() as Map<String, dynamic>;
      var products = cartData['products'] as List<dynamic>;
      for (var product in products) {
        cartItems.add({
          'title': product['title'],
          'price': product['price'],
          'quantity': product['quantity'],
        });
      }
    }

    return cartItems;
  }

  double _calculateTotal(List<Map<String, dynamic>> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      double price = double.tryParse(item['price'].toString()) ?? 0.0;
      int quantity = item['quantity'] as int? ?? 0;
      total += price * quantity;
    }
    return total;
  }

  Widget _orderSummary(List<Map<String, dynamic>> cartItems, double total) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...cartItems.map((item) {
              double price = double.tryParse(item['price'].toString()) ?? 0.0;
              int quantity = item['quantity'] is int ? item['quantity'] : 0;
              return Text('${item['title']} - \$${(price * quantity).toStringAsFixed(2)}');
            }).toList(),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _paymentCard() {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Visa Card'),
              subtitle: Text('**** **** **** 1234'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Security'),
              subtitle: Text('Your transaction is secure'),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment(BuildContext context, double total) async {
    // Handle payment processing here

    // Update Firestore to change status, status_delivery, and payment_status
    var user = FirebaseAuth.instance.currentUser;
    String userId = user?.uid ?? '';

    var querySnapshot = await FirebaseFirestore.instance
        .collection('cart')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'cart')
        .get();

    String txHash = await _createBlockchainTransaction(DateTime.timestamp().toString());

    for (var doc in querySnapshot.docs) {
      await doc.reference.update({
        'status': 'order',
        'status_delivery': 'packing',
        'payment_status': 'paid',
        'transaction_hash': txHash,
      });
    }

    // Show success message
    _showSuccessDialog(context, txHash);
  }

  Future<String> _createBlockchainTransaction(String data) async {
    try {
      // Create a simple transaction on the blockchain
      String txHash = await _blockchainService.storeProductMetadata(data);
      return txHash;
    } catch (error) {
      print("Blockchain Transaction Error: $error");
      return _formatData();
    }
  }

  String _formatData() {
    return generateProductHash(DateTime.timestamp().toString());
  }

  void _showSuccessDialog(BuildContext context, String txHash) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Payment Successful'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: txHash,
                    size: 200.0,
                    version: QrVersions.auto,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Save this QR code for future reference.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Save QR Code'),
              onPressed: () => _saveQrCode(context, txHash),
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestStoragePermission() async {
    if (await Permission.storage.isDenied) {
      final status = await Permission.storage.request();

      if (status.isGranted) {
        print("Storage permission granted");
      } else {
        print("Storage permission denied");
      }
    }
  }


  Future<void> _saveQrCode(BuildContext context, String data) async {
    await _requestStoragePermission(); // Ensure permission is requested first

    try {
      final qrCodeFile = await _generateQrCodeFile(data);

      // Check if permission was granted
      if (await Permission.storage.isGranted) {
        String downloadsDir = "/storage/emulated/0/Download";
        String filePath = "$downloadsDir/transaction_qr.png";
        await qrCodeFile.copy(filePath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code saved at $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission not granted')),
        );
      }
    } catch (e) {
      print("Error Saving QR Code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving QR code: $e')),
      );
    }
  }

  Future<File> _generateQrCodeFile(String data) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/qr_code.png';

    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: false,
      color: Colors.black,
      emptyColor: Colors.white,
    );

    final picture = await qrPainter.toImage(300);
    final byteData = await picture.toByteData(format: ImageByteFormat.png);

    final file = File(filePath);
    await file.writeAsBytes(byteData!.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }
}
