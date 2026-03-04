import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/qr_data.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../utils/hash_util.dart';
import '../widgets/identity_card_widget.dart';
import '../widgets/qr_countdown_widget.dart';
import 'login_screen_new.dart';

class UserDashboardNew extends StatefulWidget {
  final String userId;
  final String name;

  const UserDashboardNew({
    Key? key,
    required this.userId,
    required this.name,
  }) : super(key: key);

  @override
  State<UserDashboardNew> createState() => _UserDashboardNewState();
}

class _UserDashboardNewState extends State<UserDashboardNew>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? _originalHash;
  String? _qrData;
  int _currentTimestamp = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int _qrGeneration = 0;
  bool _showTechnicalDetails = false;
  int _timeRemaining = qrRefreshSeconds;
  bool _showQRSection = false; // New flag to control QR section visibility

  late AnimationController _fadeController;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchBlockchainHash();

    // Fetch user data via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUserData(widget.userId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reset timer when app comes to foreground
      _resetQRTimer();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resetQRTimer() {
    setState(() {
      _timeRemaining = qrRefreshSeconds;
    });
    _startCountdownTimer();
  }

  Future<void> _fetchBlockchainHash() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getUser(widget.userId);

      if (result['success'] == true) {
        setState(() {
          _originalHash = result['blockchain_hash'];
          _isLoading = false;
        });
        if (_originalHash != null && _originalHash!.isNotEmpty) {
          // Don't auto-generate QR, wait for biometric auth
          _showQRSection = false;
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to fetch user data';
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

  /// Show QR directly without authentication
  void _showQRDirectly() {
    setState(() {
      _showQRSection = true;
    });
    _generateQR();
    _resetQRTimer();
  }

  void _generateQR() {
    if (_originalHash == null) return;

    _currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final dynamicHash = HashUtil.generateDynamicHash(
      _originalHash!,
      _currentTimestamp,
    );
    final qrPayload = HashUtil.generateQRPayload(
      userId: widget.userId,
      timestamp: _currentTimestamp,
      dynamicHash: dynamicHash,
    );

    setState(() {
      _qrData = qrPayload;
      _qrGeneration++;
      _timeRemaining = qrRefreshSeconds;
    });

    _fadeController.forward(from: 0);
    _startCountdownTimer();
  }

  void _onTimerComplete() {
    _generateQR();
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    context.read<UserProvider>().clearUserData();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreenNew()),
      (route) => false,
    );
  }

  Future<void> _openEtherscan() async {
    final userProvider = context.read<UserProvider>();
    final txHash = userProvider.transactionHash;

    if (txHash != null && txHash.isNotEmpty) {
      final url = Uri.parse('https://sepolia.etherscan.io/tx/$txHash');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Identity'),
        actions: [
          // Theme Toggle
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
                tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
              );
            },
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Loading your identity...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final bool isNetworkError = _errorMessage?.toLowerCase().contains('internet') ??
        _errorMessage?.toLowerCase().contains('connection') ??
        _errorMessage?.toLowerCase().contains('socket') ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: AppTheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              isNetworkError
                  ? 'No internet connection. Please check your connection and try again.'
                  : _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: _fetchBlockchainHash,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        return RefreshIndicator(
          onRefresh: () async {
            await _fetchBlockchainHash();
            await userProvider.fetchUserData(widget.userId);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Digital Identity Card
                IdentityCardWidget(
                  name: user?.name ?? widget.name,
                  userId: widget.userId,
                  branch: user?.additionalAttributes?['branch']?.toString(),
                  gender: user?.additionalAttributes?['gender']?.toString(),
                  year: user?.additionalAttributes?['year']?.toString(),
                  yop: user?.additionalAttributes?['yop']?.toString(),
                  session: user?.additionalAttributes?['session']?.toString(),
                  age: user?.age?.toString(),
                  aadharNumber: user?.idNumber,
                  photoUrl: user?.additionalAttributes?['photo_url']?.toString(),
                  isVerified: userProvider.isVerifiedOnBlockchain,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // Identity Status Badge
                IdentityStatusBadge(
                  isVerified: userProvider.isVerifiedOnBlockchain,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // QR Code Section (no authentication)
                _buildQRCodeSection(),
                const SizedBox(height: AppTheme.spacingLg),
                // Technical Details (Expandable)
                _buildTechnicalDetailsSection(),
                const SizedBox(height: AppTheme.spacingLg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.qr_code,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dynamic QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Show this to a verifier',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // QR Code (no authentication required)
          if (!_showQRSection)
            // Show "Tap to Generate QR" button
            ElevatedButton.icon(
              onPressed: _showQRDirectly,
              icon: const Icon(Icons.qr_code),
              label: const Text('Tap to Generate QR'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingMd,
                ),
              ),
            )
          else if (_qrData != null)
            // Show QR Code
            FadeTransition(
              opacity: _fadeController,
              child: Column(
                children: [
                  // QR Code Container
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: QrImageView(
                      data: _qrData!,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  // Countdown Timer
                  QRCountdownWidget(
                    seconds: qrRefreshSeconds,
                    onComplete: _onTimerComplete,
                    generation: _qrGeneration,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetailsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.code,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              'View Technical Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        trailing: AnimatedRotation(
          turns: _showTechnicalDetails ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.expand_more,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _showTechnicalDetails = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              0,
              AppTheme.spacingMd,
              AppTheme.spacingMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: AppTheme.spacingSm),
                _buildTechDetail(
                  'Dynamic Hash',
                  _qrData != null
                      ? _truncateHash(QRData.fromJson(
                          HashUtil.parseQRPayload(_qrData!) ?? {},
                        ).dynamicHash)
                      : 'N/A',
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildTechDetail('Timestamp', _formatTimestamp(_currentTimestamp)),
                const SizedBox(height: AppTheme.spacingSm),
                _buildTechDetail(
                  'Time Remaining',
                  '$_timeRemaining seconds',
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildTechDetail(
                  'Blockchain Status',
                  context.read<UserProvider>().isVerifiedOnBlockchain
                      ? 'Verified'
                      : 'Not Registered',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _truncateHash(String hash) {
    if (hash.length <= 20) return hash;
    return '${hash.substring(0, 10)}...${hash.substring(hash.length - 10)}';
  }
}

class IdentityStatusBadge extends StatelessWidget {
  final bool isVerified;

  const IdentityStatusBadge({Key? key, required this.isVerified}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isVerified
            ? AppTheme.success.withOpacity(0.1)
            : AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isVerified
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.warning_amber,
            color: isVerified ? AppTheme.success : AppTheme.error,
            size: 16,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            isVerified ? 'Verified on Blockchain' : 'Not Registered',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isVerified ? AppTheme.success : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }
}