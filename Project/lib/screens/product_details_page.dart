import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopper/screens/product_verification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailsPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  ProductDetailsPage({required this.orderId, required this.orderData});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String get userId => _auth.currentUser?.uid ?? '';

  void _addToCart() async {
  try {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to add products to the cart.')),
      );
      return;
    }

    final cartRef = FirebaseFirestore.instance.collection('cart');

    // Query user's cart
    QuerySnapshot cartSnapshot = await cartRef
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'cart')
        .limit(1) // Assuming one active cart per user
        .get();

    if (cartSnapshot.docs.isNotEmpty) {
      DocumentSnapshot cartDoc = cartSnapshot.docs.first;
      Map<String, dynamic> cartData = cartDoc.data() as Map<String, dynamic>;
      List<dynamic> products = cartData['products'] ?? [];

      // Check if product is already in the cart
      bool productExists = false;

      for (var product in products) {
        if (product['id'] == widget.orderData['id']) {
          product['quantity'] += quantity;
          productExists = true;
          break;
        }
      }

      if (!productExists) {
        products.add({
          'id': widget.orderData['id'],
          'title': widget.orderData['title'],
          'price': widget.orderData['price'],
          'quantity': quantity,
          'image_url': widget.orderData['image'],
          'description': widget.orderData['description'],
        });
      }

      // Update existing cart with modified products list
      await cartRef.doc(cartDoc.id).update({
        'products': products,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      // Create a new cart document
      await cartRef.add({
        'user_id': userId,
        'products': [
          {
            'id': widget.orderData['id'],
            'title': widget.orderData['title'],
            'price': widget.orderData['price'],
            'quantity': quantity,
            'image_url': widget.orderData['image'],
            'description': widget.orderData['description'],
          }
        ],
        'status': 'cart',
        'payment_status': 'not paid',
        'status_delivery': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product added to cart successfully!')),
    );
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to add product to cart: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    // Safely access fields, using default values if necessary
    final title = widget.orderData['title'] ?? 'No Title';
    final price = widget.orderData['price'] ?? '0.0';
    final imageUrl = widget.orderData['image'] ?? '';
    final description = widget.orderData['description'] ?? 'No Description';

    return Scaffold(
      appBar: AppBar(title: Text('Product Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            imageUrl.isNotEmpty
                ? Image.network(imageUrl, height: 250, width: double.infinity, fit: BoxFit.contain)
                : Container(height: 250, color: Colors.grey, child: Center(child: Text('No Image Available'))),
            SizedBox(height: 16),

            // Title and Price
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '\$' + price,
              style: TextStyle(fontSize: 20, color: Colors.green),
            ),
            SizedBox(height: 16),

            // Description
            Text(
              description,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),

            // Quantity Counter
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                ),
                Text('Quantity: $quantity', style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),

            // Add to Cart Button
            ElevatedButton(
              onPressed: _addToCart,
              child: Text('Add to Cart'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
