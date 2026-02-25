import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verification_category.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/hash_util.dart';
import 'login_screen_new.dart';
import 'verification_result_screen_new.dart';

class VerifierScanScreen extends StatefulWidget {
  final String verifierId;
  final String name;
  final UseCase useCase;
  final VerificationCategory category;

  const VerifierScanScreen({
    Key? key,
    required this.verifierId,
    required this.name,
    required this.useCase,
    required this.category,
  }) : super(key: key);

  @override
  State<VerifierScanScreen> createState() => _VerifierScanScreenState();
}

class _VerifierScanScreenState extends State<VerifierScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreenNew()),
      (route) => false,
    );
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
      final qrPayload = HashUtil.parseQRPayload(qrData);

      if (qrPayload == null) {
        _showError('Invalid QR code format');
        setState(() => _isProcessing = false);
        return;
      }

      final userId = qrPayload['user_id'];
      final timestamp = qrPayload['timestamp'];
      final dynamicHash = qrPayload['dynamic_hash'];

      if (userId == null || timestamp == null || dynamicHash == null) {
        _showError('Missing required fields in QR code');
        setState(() => _isProcessing = false);
        return;
      }

      final result = await ApiService.verifyTimestamp(
        userId: userId.toString(),
        timestamp: int.parse(timestamp.toString()),
        dynamicHash: dynamicHash.toString(),
      );

      if (!mounted) return;

      // Navigate to result screen and wait for result
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerificationResultScreenNew(
            verificationResult: result,
            useCase: widget.useCase,
            category: widget.category,
            onScanAgain: () {
              // This won't be called directly, we handle via pop
            },
          ),
        ),
      );

      // Reset processing state when returning
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      _showError('Error processing QR code: ${e.toString()}');
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    // Check if it's a network error
    final bool isNetworkError = message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('socket');

    final displayMessage = isNetworkError
        ? 'No internet connection. Please check your connection and try again.'
        : message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(displayMessage)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    key: ValueKey(themeProvider.isDarkMode),
                  ),
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Context Info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppTheme.spacingMd),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    widget.category.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.useCase.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Scanner
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera Preview
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _handleQRScan,
                    ),
                    // Scan Overlay
                    CustomPaint(
                      size: Size.infinite,
                      painter: _ScannerOverlayPainter(),
                    ),
                    // Animated Scan Line
                    AnimatedBuilder(
                      animation: _scanLineController,
                      builder: (context, child) {
                        return Positioned(
                          top: MediaQuery.of(context).size.width *
                              0.5 *
                              _scanLineController.value,
                          left: MediaQuery.of(context).size.width * 0.15,
                          right: MediaQuery.of(context).size.width * 0.15,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Theme.of(context).colorScheme.primary,
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Corner Markers
                    Positioned(
                      top: MediaQuery.of(context).size.width * 0.15,
                      left: MediaQuery.of(context).size.width * 0.15,
                      child: _buildCornerMarker(true, true),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.width * 0.15,
                      right: MediaQuery.of(context).size.width * 0.15,
                      child: _buildCornerMarker(false, true),
                    ),
                    Positioned(
                      bottom: MediaQuery.of(context).size.width * 0.15,
                      left: MediaQuery.of(context).size.width * 0.15,
                      child: _buildCornerMarker(true, false),
                    ),
                    Positioned(
                      bottom: MediaQuery.of(context).size.width * 0.15,
                      right: MediaQuery.of(context).size.width * 0.15,
                      child: _buildCornerMarker(false, false),
                    ),
                    // Processing Overlay
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              SizedBox(height: AppTheme.spacingMd),
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
          // Instructions
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              children: [
                Text(
                  'Position QR code within the frame',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'The QR code is valid for 30 seconds. Make sure to scan quickly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerMarker(bool isLeft, bool isTop) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          left: isLeft
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                )
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                )
              : BorderSide.none,
          top: isTop
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                )
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                )
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isLeft && isTop ? const Radius.circular(12) : Radius.zero,
          topRight: !isLeft && isTop ? const Radius.circular(12) : Radius.zero,
          bottomLeft:
              isLeft && !isTop ? const Radius.circular(12) : Radius.zero,
          bottomRight:
              !isLeft && !isTop ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaSize, scanAreaSize),
          const Radius.circular(16),
        ),
      );

    canvas.drawPath(
      path..fillType = PathFillType.evenOdd,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
