import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> verificationResult;

  const ResultScreen({
    Key? key,
    required this.verificationResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool success = verificationResult['success'] ?? false;
    final Map<String, dynamic>? data = verificationResult['data'];
    final bool verified = data?['verified'] ?? false;
    final String reason = data?['reason'] ?? verificationResult['message'] ?? 'Unknown error';
    final String? userName = data?['userName'];
    final String? userId = data?['user_id'];
    final int? timeRemaining = data?['timeRemaining'];
    final String? details = data?['details'];

    final Color resultColor = verified ? Colors.green : Colors.red;
    final IconData resultIcon = verified ? Icons.check_circle : Icons.cancel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Result'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Result Icon
              Icon(
                resultIcon,
                size: 120,
                color: resultColor,
              ),
              const SizedBox(height: 24),
              
              // Result Status
              Text(
                verified ? 'VERIFIED' : 'VERIFICATION FAILED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
              ),
              const SizedBox(height: 12),
              
              // Reason
              Text(
                reason,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 32),
              
              // Details Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (userName != null) ...[
                        _buildDetailRow('Name', userName),
                        const SizedBox(height: 12),
                      ],
                      
                      if (userId != null) ...[
                        _buildDetailRow('User ID', userId),
                        const SizedBox(height: 12),
                      ],
                      
                      if (verified && timeRemaining != null) ...[
                        _buildDetailRow(
                          'Time Remaining',
                          '$timeRemaining seconds',
                          valueColor: timeRemaining <= 5 ? Colors.red : Colors.green,
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      if (details != null) ...[
                        const Divider(height: 24),
                        Text(
                          'Additional Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          details,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Info Banner
              if (!success || !verified)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getFailureAdvice(reason),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (verified)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Identity successfully verified. This user\'s credentials are authenticated via blockchain.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Back Button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Scan Another QR Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? Colors.grey[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getFailureAdvice(String reason) {
    if (reason.toLowerCase().contains('expired')) {
      return 'The QR code has expired. Please ask the user to generate a new QR code.';
    } else if (reason.toLowerCase().contains('tampered')) {
      return 'The QR code appears to have been modified. Do not proceed with verification.';
    } else if (reason.toLowerCase().contains('not registered')) {
      return 'This user has not registered their identity on the blockchain yet.';
    } else if (reason.toLowerCase().contains('database')) {
      return 'Data integrity issue detected. The stored data does not match blockchain records.';
    } else {
      return 'Verification failed. Please try again or contact support.';
    }
  }
}
