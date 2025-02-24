import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

import '../utils/qr_scanner.dart';

class VerificationPage extends StatefulWidget {
  final String transactionHash;

  VerificationPage({required this.transactionHash});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  String statusMessage = "Waiting for user action...";
  File? _imageFile;
  late Web3Client _web3Client;

  @override
  void initState() {
    super.initState();
    _web3Client = Web3Client('http://192.168.0.20:7545', Client());
  }

  Future<void> _selectImageFromGallery() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
        statusMessage = "Image selected, verifying authenticity...";
      });

      String extractedData = await _decodeQrFromFile(_imageFile!);
      if (extractedData != null) {
        await _verifyTransactionHash(extractedData);
      } else {
        setState(() {
          statusMessage = "Order verification Failed!";
        });
      }
    }
  }

  Future<String> _decodeQrFromFile(File imageFile) async {
    QrScannerService qrScannerService = QrScannerService();
      String? qrData = await qrScannerService.uploadAndDecodeQrCode(imageFile);
      return qrData;
  }

  Future<void> _verifyTransactionHash(String extractedHash) async {
    try {
      setState(() {
        statusMessage = "Checking blockchain service status...";
      });

      // Check if the blockchain service is available
      await _web3Client.getChainId();

      if (extractedHash ==  widget.transactionHash) {
        setState(() {
          statusMessage = "Order verified!";
        });
      } else {
        setState(() {
          statusMessage = "Order verification Failed!";
        });
      }
    } catch (error) {
      print(error);
      setState(() {
        statusMessage = "Order verification Failed!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Page'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Transaction Hash: ${widget.transactionHash}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _imageFile != null
                ? Image.file(_imageFile!, height: 200, fit: BoxFit.cover)
                : Text(
              "No image selected",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _selectImageFromGallery,
              icon: Icon(Icons.photo),
              label: Text("Select Image from Gallery"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.deepPurple, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
