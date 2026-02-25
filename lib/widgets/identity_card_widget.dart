import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IdentityCardWidget extends StatelessWidget {
  final String name;
  final String userId;
  final String? branch;
  final String? gender;
  final String? year;
  final String? yop;
  final String? session;
  final String? age;
  final String? aadharNumber;
  final String? photoUrl;
  final bool isVerified;

  const IdentityCardWidget({
    Key? key,
    required this.name,
    required this.userId,
    this.branch,
    this.gender,
    this.year,
    this.yop,
    this.session,
    this.age,
    this.aadharNumber,
    this.photoUrl,
    required this.isVerified,
  }) : super(key: key);

  String get _maskedAadhar {
    if (aadharNumber == null || aadharNumber!.length < 4) return 'XXXX-XXXX-XXXX';
    final last4 = aadharNumber!.substring(aadharNumber!.length - 4);
    return 'XXXX-XXXX-$last4';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.idCardGradientDark : AppTheme.idCardGradientLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowLg,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: Colors.white.withOpacity(0.9),
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(
                            'IDENTIX',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      // Verification Badge on Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? Colors.white.withOpacity(0.2)
                              : Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVerified ? Icons.verified : Icons.error,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVerified ? 'VERIFIED' : 'UNVERIFIED',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  // Profile Section
                  Row(
                    children: [
                      // Profile Photo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: photoUrl != null && photoUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholder();
                                  },
                                ),
                              )
                            : _buildPlaceholder(),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      // Name and ID
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: $userId',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  // User Details - InfoRow Style
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Column(
                      children: [
                        if (branch != null) _buildInfoRow('Branch', branch!),
                        if (year != null) _buildInfoRow('Year', year!),
                        if (yop != null) _buildInfoRow('YOP', yop!),
                        if (gender != null) _buildInfoRow('Gender', gender!),
                        if (session != null) _buildInfoRow('Session', session!),
                        if (age != null) _buildInfoRow('Age', '$age years'),
                        if (aadharNumber != null) _buildInfoRow('Aadhaar', _maskedAadhar),
                      ],
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

  Widget _buildPlaceholder() {
    return Icon(
      Icons.person,
      size: 40,
      color: Colors.white.withOpacity(0.7),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class IdentityStatusBadge extends StatelessWidget {
  final bool isVerified;

  const IdentityStatusBadge({
    Key? key,
    required this.isVerified,
  }) : super(key: key);

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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isVerified ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            isVerified ? 'Verified on Blockchain' : 'Not Registered',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isVerified ? AppTheme.success : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
