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
        description: 'Visit our official website for more information.',
      ),
      _ContactActionData(
        icon: Icons.mail_outline,
        label: 'suggestion@edums.tn',
        uri: Uri(scheme: 'mailto', path: 'suggestion@edums.tn'),
        description: 'Share your ideas and help us improve EduMS.',
      ),
      _ContactActionData(
        icon: Icons.headset_mic_outlined,
        label: 'support@edums.tn',
        uri: Uri(scheme: 'mailto', path: 'support@edums.tn'),
        description: 'Contact our support team for assistance.',
      ),
      _ContactActionData(
        icon: Icons.phone_in_talk_outlined,
        label: '+216 54 422 699',
        uri: Uri(scheme: 'tel', path: '+21654422699'),
        description: 'Give us a call during business hours.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final onPrimary = scheme.onPrimary;
    final neutralCardColor = scheme.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.45 : 0.6,
    );
    final onNeutralCard = scheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact us'),
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
      body: Container(
        color: scheme.surface,
        width: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    elevation: 12,
                    shadowColor: primary.withOpacity(0.24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: primary,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 28,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: onPrimary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.support_agent_outlined,
                              color: onPrimary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                            'We are here to help! Reach out to our team using your preferred method below.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: onPrimary.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 8,
                    shadowColor: scheme.shadow.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: neutralCardColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Contact information',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: onNeutralCard,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Choose one of the contact options below to reach our team directly.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onNeutralCard.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 28),
                          ..._buildContactActions(theme, onNeutralCard),
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

  List<Widget> _buildContactActions(ThemeData theme, Color onCardColor) {
    final primary = theme.colorScheme.primary;

    final widgets = <Widget>[];
    for (var i = 0; i < _actions.length; i++) {
      widgets.add(_buildContactAction(theme, _actions[i], primary, onCardColor));
      if (i != _actions.length - 1) {
        widgets.add(
          Divider(
            color: theme.colorScheme.outlineVariant.withOpacity(0.35),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildContactAction(
    ThemeData theme,
    _ContactActionData action,
    Color primary,
    Color onCardColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUri(action.uri),
        borderRadius: BorderRadius.circular(18),
        splashColor: onCardColor.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withOpacity(0.12),
                ),
                child: Icon(
                  action.icon,
                  color: primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onCardColor,
                      ),
                    ),
                    if (action.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        action.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onCardColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: onCardColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: onCardColor,
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
    this.description,
  });

  final IconData icon;
  final String label;
  final Uri uri;
  final String? description;
}
