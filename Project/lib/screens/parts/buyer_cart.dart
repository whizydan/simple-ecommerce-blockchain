import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Stream<QuerySnapshot> _cartStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _cartStream = FirebaseFirestore.instance
        .collection('cart')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'cart')
        .snapshots();
  }

  double _calculateTotal(List<dynamic> products) {
    double total = 0;
    for (var product in products) {
      double price = double.tryParse(product['price'].toString()) ?? 0.0;
      int quantity = int.tryParse(product['quantity'].toString()) ?? 0;
      total += price * quantity;
    }
    return total;
  }

  void _updateQuantity(String cartId, String productId, int quantity) async {
    DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(cartId);
    var cartSnapshot = await cartRef.get();
    List<dynamic> products = List.from(cartSnapshot['products']);

    // Find the correct product and update quantity
    for (var product in products) {
      if (product['id'] == productId) {
        product['quantity'] = quantity;
        break;
      }
    }

    await cartRef.update({'products': products});
  }

  void _removeProduct(String cartId, String productId) async {
    DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(cartId);
    var cartSnapshot = await cartRef.get();
    List<dynamic> products = List.from(cartSnapshot['products']);

    // Remove the correct product
    products.removeWhere((product) => product['id'] == productId);

    await cartRef.update({'products': products});
  }

  void _checkout(String cartId, double total) {
    Navigator.pushNamed(context, '/checkout', arguments: {'cartId': cartId, 'total': total});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _cartStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Your cart is empty'));
        }

        List<Map<String, dynamic>> allProducts = [];

        for (var cartDoc in snapshot.data!.docs) {
          var products = cartDoc['products'] as List<dynamic>;
          for (var product in products) {
            allProducts.add({
              ...product,
              'cartId': cartDoc.id, // Attach the cart ID to each product
            });
          }
        }

        double total = _calculateTotal(allProducts);

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: allProducts.length,
                itemBuilder: (context, index) {
                  var product = allProducts[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Image.network(product['image_url'], width: 50, height: 50),
                      title: Text(product['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('\$${(double.tryParse(product['price'].toString()) ?? 0.0).toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              if (product['quantity'] > 1) {
                                _updateQuantity(product['cartId'], product['id'], product['quantity'] - 1);
                              }
                            },
                          ),
                          Text('${product['quantity']}'),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              _updateQuantity(product['cartId'], product['id'], product['quantity'] + 1);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeProduct(product['cartId'], product['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _checkout(snapshot.data!.docs.first.id, total),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Checkout \$${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        );
      },
    );
  }
}
