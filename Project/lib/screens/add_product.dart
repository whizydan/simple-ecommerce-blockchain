import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:shopper/utils/image_upload.dart';
import 'dart:convert';
import 'dart:io';

import '../utils/blockchain_service.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final BlockchainService _blockchainService = BlockchainService();
  File? _image;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeBlockchainService();
  }

  Future<void> _initializeBlockchainService() async {
    await _blockchainService.init();
    print("Blockchain service initialized.");
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _saveProduct() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();
    String price = _priceController.text.trim();

    if (title.isEmpty || description.isEmpty || price.isEmpty || _image == null) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Please fill in all fields and select an image.';
      });
      return;
    }

    try {
      // Upload image and get URL
      String imageUrl = await ImageUploader.uploadToCloudinary(_image!);

      // Generate unique product ID using timestamp
      String productID = DateTime.now().millisecondsSinceEpoch.toString();
      String productHash = generateProductHash(productID, title, description);
      String txHash = productHash;

      // Store product metadata on blockchain
      try{
        txHash = await _blockchainService.storeProductMetadata(productHash);
      }catch(error){
        print("Error storing product metadata on blockchain: $error");
      }

      // Add product to Firestore
      await FirebaseFirestore.instance.collection('products').doc(productID).set({
        'id': productID,
        'title': title,
        'description': description,
        'price': double.parse(price),
        'image_url': imageUrl,
        'blockchain_tx': txHash,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
        _statusMessage = 'Product added successfully!\nTransaction Hash: $txHash';
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  String generateProductHash(String productID, String productName, String productDescription) {
    final input = '$productID$productName$productDescription';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Product')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _image == null
                    ? Center(child: Text('Tap to select image'))
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Center(
              child: ElevatedButton(
                onPressed: _saveProduct,
                child: Text('Save Product'),
              ),
            ),
            SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Center(
                child: Text(
                  _statusMessage,
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
