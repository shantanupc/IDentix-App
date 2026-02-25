import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/verification_category.dart';

class VerificationResultWidget extends StatelessWidget {
  final bool isSuccess;
  final VerificationCategory? category;
  final UseCase? useCase;
  final String? reason;
  final Map<String, dynamic>? details;
  final VoidCallback onScanAgain;

  const VerificationResultWidget({
    Key? key,
    required this.isSuccess,
    this.category,
    this.useCase,
    this.reason,
    this.details,
    required this.onScanAgain,
  }) : super(key: key);

  String get _title {
    if (isSuccess) {
      return 'Identity Verified';
    } else {
      return 'Verification Failed';
    }
  }

  String get _subtitle {
    if (!isSuccess) {
      return reason ?? 'Verification could not be completed';
    }

    // Build detailed success message based on category and actual values
    final userData = details?['userData'] as Map<String, dynamic>?;
    final age = userData?['age'] ?? details?['age'];
    final branch = userData?['branch'] ?? details?['branch'];
    final year = userData?['year'] ?? details?['year'];
    final name = userData?['name'] ?? details?['userName'] ?? details?['name'];

    switch (category) {
      case VerificationCategory.ageVerification:
        if (age != null) {
          return 'User is $age years old and above 18.';
        }
        return 'User is above 18 years of age.';

      case VerificationCategory.branchVerification:
        if (branch != null) {
          return 'User belongs to $branch branch.';
        }
        return 'User branch verified successfully.';

      case VerificationCategory.yearVerification:
        if (year != null) {
          return 'User is in $year.';
        }
        return 'User academic year verified.';

      case VerificationCategory.fullIdentity:
        final List<String> verifiedInfo = [];
        if (name != null) verifiedInfo.add('Name: $name');
        if (age != null) verifiedInfo.add('Age: $age');
        if (branch != null) verifiedInfo.add('Branch: $branch');
        if (year != null) verifiedInfo.add('Year: $year');

        if (verifiedInfo.isNotEmpty) {
          return 'All identity details verified:\n${verifiedInfo.join('\n')}';
        }
        return 'All identity details verified successfully.';

      case VerificationCategory.aadharVerification:
        return 'Aadhar details verified successfully.';

      default:
        if (useCase == UseCase.hotelCheckIn) {
          return 'Guest identity verified successfully.';
        }
        return 'Identity verification completed successfully.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success/Failure Icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSuccess
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.error.withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.cancel,
                size: 80,
                color: isSuccess ? AppTheme.success : AppTheme.error,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Title
          Text(
            _title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isSuccess ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Subtitle
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Details Card
          if (details != null && details!.isNotEmpty)
            _buildDetailsCard(context),
          const SizedBox(height: AppTheme.spacingXl),
          // Scan Again Button
          ElevatedButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final userData = details?['userData'] as Map<String, dynamic>?;
    final userName = userData?['name'] ?? details?['userName']?.toString();
    final userId = userData?['user_id'] ?? details?['user_id']?.toString();
    final timeRemaining = details?['timeRemaining'] as int?;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (userName != null) ...[
              _buildDetailRow(context, 'Name', userName),
              const SizedBox(height: AppTheme.spacingSm),
            ],
            if (userId != null) ...[
              _buildDetailRow(context, 'User ID', userId),
              const SizedBox(height: AppTheme.spacingSm),
            ],
            if (category != null) ...[
              _buildDetailRow(context, 'Category', category!.displayName),
              const SizedBox(height: AppTheme.spacingSm),
            ],
            if (timeRemaining != null) ...[
              _buildDetailRow(
                context,
                'Time Remaining',
                '$timeRemaining seconds',
                valueColor: timeRemaining <= 5 ? AppTheme.error : AppTheme.success,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class VerificationStatusBanner extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const VerificationStatusBanner({
    Key? key,
    required this.isSuccess,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: isSuccess
            ? AppTheme.success.withOpacity(0.1)
            : AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isSuccess
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.verified : Icons.warning_amber,
            color: isSuccess ? AppTheme.success : AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
