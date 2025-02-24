import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;

  AdminProductDetails({required this.product});

  @override
  _AdminProductDetailsState createState() => _AdminProductDetailsState();
}

class _AdminProductDetailsState extends State<AdminProductDetails> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current product data
    _titleController = TextEditingController(text: widget.product['title']);
    _descriptionController = TextEditingController(text: widget.product['description']);
    _priceController = TextEditingController(text: widget.product['price'].toString());
    _imageUrlController = TextEditingController(text: widget.product['image_url']);
  }

  // Function to update the product details in Firestore
  Future<void> _updateProduct() async {
    // Retrieve updated values
    String updatedTitle = _titleController.text.trim();
    String updatedDescription = _descriptionController.text.trim();
    double updatedPrice = double.parse(_priceController.text.trim());
    String updatedImageUrl = _imageUrlController.text.trim();

    // Get the product ID from Firestore
    String productId = widget.product['id'];

    try {
      // Update the product in Firestore
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'title': updatedTitle,
        'description': updatedDescription,
        'price': updatedPrice,
        'image_url': updatedImageUrl,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product updated successfully!')),
      );

      // Pop the page to return to the previous screen
      Navigator.pop(context);
    } catch (e) {
      // Show error message if update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product Details')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                widget.product['image_url'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Product Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Product Description',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _updateProduct,
                  child: Text('Update Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
