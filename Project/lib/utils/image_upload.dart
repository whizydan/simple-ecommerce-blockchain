import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ImageUploader {
  // Upload image to Firebase Storage
  static Future<String?> uploadToFirebase(File imageFile) async {
    try {
      String fileName = basename(imageFile.path);
      Reference storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName');
      UploadTask uploadTask = storageRef.putFile(imageFile);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading to Firebase: $e');
      return null;
    }
  }

  static Future<String> uploadToCloudinary(File file) async {
    final cloudinary = Cloudinary.basic(
      cloudName: "dizc6v0xl",
    );

    final response = await cloudinary.unsignedUploadResource(
        CloudinaryUploadResource(
            uploadPreset: "ml_default",
            filePath: file.path,
            fileBytes: file.readAsBytesSync(),
            resourceType: CloudinaryResourceType.image,
            folder: "images",
            fileName: DateTime.timestamp().toString(),
            progressCallback: (count, total) {
              print(
                  'Uploading image from file with progress: $count/$total');
            })
    );

    if(response.isSuccessful) {
      print('Get your image from with ${response.secureUrl}');
      return response.secureUrl ?? "";
    }else{
      return "";
    }

  }

  static Future<String?> getImageFromCloudinary(String imageUrl) async {
    final cloudinaryImage = CloudinaryImage(imageUrl);
    return cloudinaryImage.transform().width(256).height(256).thumb().face().opacity(30).angle(45).generate();
  }

  // Upload image to PHP server
  static Future<String?> uploadToPHPServer(File imageFile) async {
    try {
      String url = 'https://demo.mbivu.com/upload.php';
      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        return responseData; // Assuming the PHP script returns the uploaded image URL
      } else {
        print('Failed to upload to PHP server. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading to PHP server: $e');
      return null;
    }
  }
}
