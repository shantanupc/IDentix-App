import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verification_category.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/use_case_card_widget.dart';
import 'login_screen_new.dart';
import 'verifier_category_screen.dart';

class VerifierUseCaseScreen extends StatefulWidget {
  final String verifierId;
  final String name;

  const VerifierUseCaseScreen({
    Key? key,
    required this.verifierId,
    required this.name,
  }) : super(key: key);

  @override
  State<VerifierUseCaseScreen> createState() => _VerifierUseCaseScreenState();
}

class _VerifierUseCaseScreenState extends State<VerifierUseCaseScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Use Case'),
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
              // Verifier Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verifier ID: ${widget.verifierId}',
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
              const SizedBox(height: AppTheme.spacingLg),
              // Section Title
              Text(
                'What would you like to verify?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Select a use case to continue',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // Use Case Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppTheme.spacingMd,
                  crossAxisSpacing: AppTheme.spacingMd,
                  childAspectRatio: 0.85,
                  children: UseCase.values.map((useCase) {
                    return UseCaseCardWidget(
                      useCase: useCase,
                      isSelected: false,
                      onTap: () => _selectUseCase(useCase),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectUseCase(UseCase useCase) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifierCategoryScreen(
          verifierId: widget.verifierId,
          name: widget.name,
          useCase: useCase,
        ),
      ),
    );
  }
}
