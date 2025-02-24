import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../order_details_page.dart';
import '../product_details_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search products...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: _firestore.collection('products').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No products available"));
              }

              List<Map<String, dynamic>> products = snapshot.data!.docs.map((doc) {
                return {
                  'id': doc.id,
                  'title': doc['title'],
                  'price': doc['price'].toString(),
                  'image': doc['image_url'],
                  'description': doc['description'],
                  'blockchain_tx': doc['blockchain_tx'],
                  'timestamp': doc['timestamp']
                };
              }).where((product) {
                return product['title'].toLowerCase().contains(_searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Image.network(
                          products[index]["image"],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/error.png', // Default image
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      title: Text(products[index]["title"],
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(products[index]["price"],
                          style: TextStyle(color: Colors.green)),
                      trailing: Icon(Icons.add_shopping_cart),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsPage(
                              orderId: products[index]["id"],
                              orderData: products[index],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
