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
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact us'),
        backgroundColor: primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/CU.png',
                    width: 320,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: theme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get in touch with EduMS',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Choose one of the contact options below to reach our team directly.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 28),
                          ..._buildContactActions(theme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContactActions(ThemeData theme) {
    final primary = theme.colorScheme.primary;

    final widgets = <Widget>[];
    for (var i = 0; i < _actions.length; i++) {
      widgets.add(_buildContactAction(theme, _actions[i], primary));
      if (i != _actions.length - 1) {
        widgets.add(const Divider());
      }
    }
    return widgets;
  }

  Widget _buildContactAction(
    ThemeData theme,
    _ContactActionData action,
    Color primary,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUri(action.uri),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  color: primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  action.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: primary,
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
