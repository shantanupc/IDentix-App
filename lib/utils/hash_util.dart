import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtil {
  // Generate dynamic hash for time-bound QR
  // dynamic_hash = SHA256(original_hash + ':' + timestamp)
  static String generateDynamicHash(String originalHash, int timestamp) {
    final payload = '$originalHash:$timestamp';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate QR payload
  static String generateQRPayload({
    required String userId,
    required int timestamp,
    required String dynamicHash,
  }) {
    final qrData = {
      'user_id': userId,
      'timestamp': timestamp,
      'dynamic_hash': dynamicHash,
    };
    return jsonEncode(qrData);
  }

  // Parse QR payload
  static Map<String, dynamic>? parseQRPayload(String qrData) {
    try {
      return jsonDecode(qrData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
