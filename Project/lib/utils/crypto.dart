import 'package:crypto/crypto.dart';
import 'dart:convert';

String generateProductHash(input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);

  return digest.toString();
}
