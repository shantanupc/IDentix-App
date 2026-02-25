import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import '../utils/hash_util.dart';
import 'login_screen.dart';
import 'result_screen.dart';

class VerifierDashboard extends StatefulWidget {
  final String verifierId;
  final String name;

  const VerifierDashboard({
    Key? key,
    required this.verifierId,
    required this.name,
  }) : super(key: key);

  @override
  State<VerifierDashboard> createState() => _VerifierDashboardState();
}

class _VerifierDashboardState extends State<VerifierDashboard> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQRScan(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse QR data
      final qrPayload = HashUtil.parseQRPayload(qrData);

      if (qrPayload == null) {
        _showError('Invalid QR code format');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final userId = qrPayload['user_id'];
      final timestamp = qrPayload['timestamp'];
      final dynamicHash = qrPayload['dynamic_hash'];

      if (userId == null || timestamp == null || dynamicHash == null) {
        _showError('Missing required fields in QR code');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Call verification API
      final result = await ApiService.verifyTimestamp(
        userId: userId.toString(),
        timestamp: int.parse(timestamp.toString()),
        dynamicHash: dynamicHash.toString(),
      );

      if (!mounted) return;

      // Navigate to result screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            verificationResult: result,
          ),
        ),
      );

      // Reset processing state after returning from result screen
      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      _showError('Error processing QR code: ${e.toString()}');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        title: const Text('Verifier Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Verifier Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.verified_user,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verifier ID: ${widget.verifierId}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Scan QR Code to Verify Identity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Position the QR code within the frame below',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Scanner
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _handleQRScan,
                    ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Verifying...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Info Banner
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.amber[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'QR codes are valid for $qrRefreshSeconds seconds. Scan quickly for accurate verification.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
