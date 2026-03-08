import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/wizard_preferences.dart';

/// Welcome wizard screen to introduce new users to the app
class WelcomeWizardScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const WelcomeWizardScreen({super.key, this.onCompleted});

  @override
  State<WelcomeWizardScreen> createState() => _WelcomeWizardScreenState();
}

class _WelcomeWizardScreenState extends State<WelcomeWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWizard();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeWizard() async {
    await WizardPreferences.setWizardCompleted(true);
    if (mounted) {
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l10n.wizardBack),
                    )
                  else
                    const SizedBox(width: 80),
                  if (_currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _completeWizard,
                      child: Text(l10n.wizardSkip),
                    )
                  else
                    const SizedBox(width: 80),
                ],
              ),
            ),

            // Page view with wizard content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildWelcomePage(context, l10n, colorScheme),
                  _buildConnectingPage(context, l10n, colorScheme),
                  _buildChannelPage(context, l10n, colorScheme),
                  _buildContactsPage(context, l10n, colorScheme),
                  _buildMapPage(context, l10n, colorScheme),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: _currentPage == index ? 12.0 : 8.0,
                    height: _currentPage == index ? 12.0 : 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage < _totalPages - 1
                        ? l10n.wizardNext
                        : l10n.wizardGetStarted,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return _buildPage(
      icon: Icons.waving_hand,
      iconColor: Colors.orange,
      title: l10n.wizardWelcomeTitle,
      description: l10n.wizardWelcomeDescription,
      colorScheme: colorScheme,
    );
  }

  Widget _buildConnectingPage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return _buildPage(
      icon: Icons.bluetooth_searching,
      iconColor: Colors.blue,
      title: l10n.wizardConnectingTitle,
      description: l10n.wizardConnectingDescription,
      features: [
        _FeatureItem(icon: Icons.radio, text: l10n.wizardConnectingFeature1),
        _FeatureItem(icon: Icons.link, text: l10n.wizardConnectingFeature2),
        _FeatureItem(icon: Icons.wifi_off, text: l10n.wizardConnectingFeature3),
      ],
      colorScheme: colorScheme,
    );
  }

  Widget _buildChannelPage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return _buildPage(
      icon: Icons.campaign,
      iconColor: Colors.purple,
      title: l10n.wizardChannelTitle,
      description: l10n.wizardChannelDescription,
      features: [
        _FeatureItem(icon: Icons.public, text: l10n.wizardChannelFeature1),
        _FeatureItem(icon: Icons.groups, text: l10n.wizardChannelFeature2),
        _FeatureItem(icon: Icons.send, text: l10n.wizardChannelFeature3),
      ],
      colorScheme: colorScheme,
    );
  }

  Widget _buildContactsPage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return _buildPage(
      icon: Icons.people,
      iconColor: Colors.teal,
      title: l10n.wizardContactsTitle,
      description: l10n.wizardContactsDescription,
      features: [
        _FeatureItem(icon: Icons.person_add, text: l10n.wizardContactsFeature1),
        _FeatureItem(icon: Icons.chat, text: l10n.wizardContactsFeature2),
        _FeatureItem(
          icon: Icons.battery_std,
          text: l10n.wizardContactsFeature3,
        ),
      ],
      colorScheme: colorScheme,
    );
  }

  Widget _buildMapPage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return _buildPage(
      icon: Icons.map,
      iconColor: Colors.red,
      title: l10n.wizardMapTitle,
      description: l10n.wizardMapDescription,
      features: [
        _FeatureItem(icon: Icons.location_on, text: l10n.wizardMapFeature1),
        _FeatureItem(
          icon: Icons.person_pin_circle,
          text: l10n.wizardMapFeature2,
        ),
        _FeatureItem(icon: Icons.offline_pin, text: l10n.wizardMapFeature3),
        _FeatureItem(icon: Icons.draw, text: l10n.wizardMapFeature4),
      ],
      colorScheme: colorScheme,
    );
  }

  Widget _buildPage({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    List<_FeatureItem>? features,
    required ColorScheme colorScheme,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Icon
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: iconColor),
          ),
          const SizedBox(height: 32),
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (features != null && features.isNotEmpty) ...[
            const SizedBox(height: 32),
            // Features list
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(feature.icon, color: colorScheme.primary, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        feature.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String text;

  _FeatureItem({required this.icon, required this.text});
}
