import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verification_category.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/use_case_card_widget.dart';
import 'login_screen_new.dart';
import 'verifier_scan_screen.dart';

class VerifierCategoryScreen extends StatefulWidget {
  final String verifierId;
  final String name;
  final UseCase useCase;

  const VerifierCategoryScreen({
    Key? key,
    required this.verifierId,
    required this.name,
    required this.useCase,
  }) : super(key: key);

  @override
  State<VerifierCategoryScreen> createState() => _VerifierCategoryScreenState();
}

class _VerifierCategoryScreenState extends State<VerifierCategoryScreen> {
  VerificationCategory? _selectedCategory;

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreenNew()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.useCase.availableCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.useCase.displayName),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Use Case Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(
                        widget.useCase.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.useCase.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.useCase.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Change Use Case',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // Section Title
              Text(
                'Select Verification Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'What information do you need to verify?',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // Category List
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.spacingSm),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return VerificationCategoryCard(
                      category: category,
                      isSelected: _selectedCategory == category,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedCategory != null ? _proceedToScan : null,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Continue to Scan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToScan() {
    if (_selectedCategory == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifierScanScreen(
          verifierId: widget.verifierId,
          name: widget.name,
          useCase: widget.useCase,
          category: _selectedCategory!,
        ),
      ),
    );
  }
}
