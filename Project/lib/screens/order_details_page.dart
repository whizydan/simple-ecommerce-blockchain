import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  OrderDetailsPage({required this.orderId, required this.orderData});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late TextEditingController _paymentStatusController;
  String _selectedDeliveryStatus = 'shipped'; // Default value
  String _userAddress = 'Fetching...';
  String _userPhone = 'Fetching...';

  @override
  void initState() {
    super.initState();
    _paymentStatusController = TextEditingController(
      text: widget.orderData['payment_status']?.toString() ?? 'N/A',
    );

    // Set the initial selected value based on existing order data
    _selectedDeliveryStatus = widget.orderData['status_delivery']?.toString() ?? 'shipped';

    // Fetch user address and phone
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    String userId = widget.orderData['user_id'] ?? '';

    if (userId.isNotEmpty) {
      try {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          setState(() {
            _userAddress = userSnapshot['address'] ?? 'No Address Available';
            _userPhone = userSnapshot['phone'] ?? 'No Phone Available';
          });
        } else {
          setState(() {
            _userAddress = 'No Address Available';
            _userPhone = 'No Phone Available';
          });
        }
      } catch (e) {
        setState(() {
          _userAddress = 'Error fetching address';
          _userPhone = 'Error fetching phone';
        });
      }
    } else {
      setState(() {
        _userAddress = 'User ID not found';
        _userPhone = 'User ID not found';
      });
    }
  }

  void _updateOrder() async {
    try {
      await FirebaseFirestore.instance.collection('cart').doc(widget.orderId).update({
        'payment_status': _paymentStatusController.text,
        'status_delivery': _selectedDeliveryStatus, // Use selected value
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var products = widget.orderData['products'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${widget.orderId}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Products:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...products.map<Widget>((product) {
              return ListTile(
                leading: Image.network(
                  product['image_url'] ?? 'https://placehold.co/400',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(product['title'] ?? 'Unknown Product'),
                subtitle: Text('Qty: ${product['quantity'] ?? 0} x \$${(product['price'] ?? 0.0).toString()}'),
              );
            }).toList(),
            SizedBox(height: 20),

            // Payment Status
            TextField(
              controller: _paymentStatusController,
              decoration: InputDecoration(labelText: 'Payment Status'),
            ),
            SizedBox(height: 20),

            // User Address & Phone
            Text('User Address:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_userAddress, style: TextStyle(fontSize: 14)),
            SizedBox(height: 10),
            Text('User Phone:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_userPhone, style: TextStyle(fontSize: 14)),
            SizedBox(height: 20),

            // Delivery Status
            Text('Delivery Status:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Radio<String>(
                  value: 'shipped',
                  groupValue: _selectedDeliveryStatus,
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryStatus = value!;
                    });
                  },
                ),
                Text('Shipped'),
                SizedBox(width: 20),
                Radio<String>(
                  value: 'delivered',
                  groupValue: _selectedDeliveryStatus,
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryStatus = value!;
                    });
                  },
                ),
                Text('Delivered'),
              ],
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _updateOrder,
              child: Text('Update Order'),
            ),
          ],
        ),
      ),
    );
  }
}
