import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';

class ApiService {
  // Login
  static Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$loginEndpoint');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final jsonResponse = jsonDecode(response.body);
      return LoginResponse.fromJson(jsonResponse);
    } on SocketException catch (_) {
      return LoginResponse(
        success: false,
        message: 'No internet connection. Please check your connection and try again.',
      );
    } on FormatException catch (_) {
      return LoginResponse(
        success: false,
        message: 'Invalid response from server. Please try again later.',
      );
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get User Data
  static Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final url = Uri.parse('$baseUrl$getUserEndpoint/$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        return {
          'success': true,
          'user': UserModel.fromJson(jsonResponse['data']),
          'blockchain_hash': jsonResponse['data']['blockchain_hash'],
          'transaction_hash': jsonResponse['data']['transaction_hash'],
          'block_number': jsonResponse['data']['block_number'],
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to fetch user',
        };
      }
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your connection and try again.',
      };
    } on FormatException catch (_) {
      return {
        'success': false,
        'message': 'Invalid response from server. Please try again later.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Verify Timestamp-Based QR
  static Future<Map<String, dynamic>> verifyTimestamp({
    required String userId,
    required int timestamp,
    required String dynamicHash,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$verifyTimestampEndpoint');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'timestamp': timestamp,
          'dynamic_hash': dynamicHash,
        }),
      ).timeout(const Duration(seconds: 10));

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        return {
          'success': true,
          'data': jsonResponse['data'],
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Verification failed',
        };
      }
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your connection and try again.',
      };
    } on FormatException catch (_) {
      return {
        'success': false,
        'message': 'Invalid response from server. Please try again later.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get blockchain hash from user endpoint
  static Future<String?> getBlockchainHash(String userId) async {
    final result = await getUser(userId);
    if (result['success'] == true) {
      return result['blockchain_hash'];
    }
    return null;
  }
}
