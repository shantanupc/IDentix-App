import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import '../utils/hash_util.dart';
import '../widgets/countdown_timer.dart';
import 'login_screen.dart';

class UserDashboard extends StatefulWidget {
  final String userId;
  final String name;

  const UserDashboard({
    Key? key,
    required this.userId,
    required this.name,
  }) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String? _originalHash;
  String? _qrData;
  int _currentTimestamp = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int _qrGeneration = 0;

  @override
  void initState() {
    super.initState();
    _fetchBlockchainHash();
  }

  Future<void> _fetchBlockchainHash() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final result = await ApiService.getUser(widget.userId);

    if (result['success'] == true &&
        result['blockchain_hash'] != null) {

      print("Blockchain hash from API: ${result['blockchain_hash']}");

      setState(() {
        _originalHash = result['blockchain_hash'];
        _isLoading = false;
      });

      _generateQR();
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Blockchain hash not found';
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Error: ${e.toString()}';
      _isLoading = false;
    });
  }
}

  void _generateQR() {
    if (_originalHash == null) return;

    // Get current timestamp in seconds
    _currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Generate dynamic hash
    final dynamicHash = HashUtil.generateDynamicHash(_originalHash!, _currentTimestamp);

    // Generate QR payload
    final qrPayload = HashUtil.generateQRPayload(
      userId: widget.userId,
      timestamp: _currentTimestamp,
      dynamicHash: dynamicHash,
    );

    setState(() {
      _qrData = qrPayload;
      _qrGeneration++;
    });
  }

  void _onTimerComplete() {
    // Auto-refresh QR when timer completes
    _generateQR();
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchBlockchainHash,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // User Info Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${widget.userId}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // QR Code Section
                      Text(
                        'Your Dynamic QR Code',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This QR code refreshes every $qrRefreshSeconds seconds',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // QR Code
                      if (_qrData != null)
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: QrImageView(
                              data: _qrData!,
                              version: QrVersions.auto,
                              size: 280,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                      
                      // Countdown Timer
                      CountdownTimer(
                        key: ValueKey(_qrGeneration),
                        seconds: qrRefreshSeconds,
                        onComplete: _onTimerComplete,
                      ),
                      const SizedBox(height: 24),
                      
                      // Info Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Show this QR code to a verifier for identity verification. The code is valid for $qrRefreshSeconds seconds.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
