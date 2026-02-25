import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  String? _blockchainHash;
  String? _transactionHash;
  String? _blockNumber;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  String? get blockchainHash => _blockchainHash;
  String? get transactionHash => _transactionHash;
  String? get blockNumber => _blockNumber;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isVerifiedOnBlockchain => _blockchainHash != null && _blockchainHash!.isNotEmpty;

  Future<void> fetchUserData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getUser(userId);

      if (result['success'] == true) {
        _user = result['user'];
        _blockchainHash = result['blockchain_hash'];

        // Parse additional blockchain info if available
        if (result['transaction_hash'] != null) {
          _transactionHash = result['transaction_hash'];
        }
        if (result['block_number'] != null) {
          _blockNumber = result['block_number'].toString();
        }
      } else {
        _errorMessage = result['message'] ?? 'Failed to fetch user data';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearUserData() {
    _user = null;
    _blockchainHash = null;
    _transactionHash = null;
    _blockNumber = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setBlockchainInfo({
    String? hash,
    String? transactionHash,
    String? blockNumber,
  }) {
    _blockchainHash = hash;
    _transactionHash = transactionHash;
    _blockNumber = blockNumber;
    notifyListeners();
  }
}
