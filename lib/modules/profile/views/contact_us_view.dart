import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsView extends StatefulWidget {
  const ContactUsView({super.key});

  @override
  State<ContactUsView> createState() => _ContactUsViewState();
}

class _ContactUsViewState extends State<ContactUsView> {
  late final List<_ContactActionData> _actions;

  @override
  void initState() {
    super.initState();
    _actions = [
      _ContactActionData(
        icon: Icons.language_outlined,
        label: 'www.edums.tn',
        uri: Uri.parse('https://www.edums.tn'),
      ),
      _ContactActionData(
        icon: Icons.mail_outline,
        label: 'suggestion@edums.tn',
        uri: Uri(scheme: 'mailto', path: 'suggestion@edums.tn'),
      ),
      _ContactActionData(
        icon: Icons.headset_mic_outlined,
        label: 'support@edums.tn',
        uri: Uri(scheme: 'mailto', path: 'support@edums.tn'),
      ),
      _ContactActionData(
        icon: Icons.phone_in_talk_outlined,
        label: '+216 54 422 699',
        uri: Uri(scheme: 'tel', path: '+21654422699'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact us'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: onPrimary,
      ),
      body: Container(
        color: theme.colorScheme.primary,
        width: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get in touch with EduMS',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose one of the contact options below to reach our team directly.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: onPrimary.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    alignment: WrapAlignment.center,
                    children: _actions
                        .map((action) => _buildContactAction(theme, action, onPrimary))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactAction(
    ThemeData theme,
    _ContactActionData action,
    Color onPrimary,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUri(action.uri),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: onPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUri(Uri uri) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showLaunchError();
      }
    } catch (_) {
      _showLaunchError();
    }
  }

  void _showLaunchError() {
    Get.snackbar(
      'Unable to open link',
      'Please try again later or use another contact option.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}

class _ContactActionData {
  const _ContactActionData({
    required this.icon,
    required this.label,
    required this.uri,
  });

  final IconData icon;
  final String label;
  final Uri uri;
}
