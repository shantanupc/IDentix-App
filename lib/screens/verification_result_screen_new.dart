import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/verification_category.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/verification_result_widget.dart';

class VerificationResultScreenNew extends StatelessWidget {
  final Map<String, dynamic> verificationResult;
  final UseCase useCase;
  final List<VerificationCategory> categories;
  final VoidCallback onScanAgain;

  const VerificationResultScreenNew({
    Key? key,
    required this.verificationResult,
    required this.useCase,
    required this.categories,
    required this.onScanAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? data = verificationResult['data'];
    final bool verified = data?['verified'] ?? false;
    final String reason = data?['reason'] ??
        verificationResult['message'] ??
        'Unknown error';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Result'),
        automaticallyImplyLeading: false,
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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            children: [
              // Result Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: verified
                        ? AppTheme.success.withOpacity(0.3)
                        : AppTheme.error.withOpacity(0.3),
                  ),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: VerificationResultWidget(
                  isSuccess: verified,
                  categories: categories,
                  useCase: useCase,
                  reason: reason,
                  details: data,
                  onScanAgain: () {
                    // Pop back to scan screen
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // Context Summary
              _buildContextSummary(context),
              const SizedBox(height: AppTheme.spacingLg),
              // Back to Categories Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Categories'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Context',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildContextRow(
            context,
            'Use Case',
            useCase.displayName,
            useCase.icon,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildContextRow(
            context,
            'Categories',
            categories.length == 1
                ? categories.first.displayName
                : '${categories.length} selected',
            categories.length == 1 ? categories.first.icon : Icons.checklist,
          ),
        ],
      ),
    );
  }

  Widget _buildContextRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
