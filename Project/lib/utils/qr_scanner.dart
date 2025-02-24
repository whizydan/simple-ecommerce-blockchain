import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class QrScannerService {
  final String apiUrl = "https://api.qrserver.com/v1/read-qr-code/";

  /// Uploads an image to the server and decodes the QR code
  Future<String> uploadAndDecodeQrCode(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      request.fields['MAX_FILE_SIZE'] = '1048576'; // Set max file size

      var response = await request.send();

      // Read stream only once
      String responseBody = await response.stream.bytesToString();
      print(responseBody); // Debugging: Print the response

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);

        // Extract the QR data from the response
        var qrData = jsonResponse[0]['symbol'][0]['data'];
        var error = jsonResponse[0]['symbol'][0]['error'];

        if (qrData != null) {
          return qrData;
        }else{
          return "NULL";
        }
      } else {
        throw Exception("Failed to decode QR code. HTTP Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error decoding QR code: $e");
    }
  }
}
