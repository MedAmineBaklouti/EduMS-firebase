import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/widgets/module_page_container.dart';

class ContactUsView extends StatefulWidget {
  const ContactUsView({super.key});

  @override
  State<ContactUsView> createState() => _ContactUsViewState();
}

class _ContactUsViewState extends State<ContactUsView> {
  late final List<_ContactSectionData> _sections;

  @override
  void initState() {
    super.initState();
    _sections = [
      _ContactSectionData(
        title: 'Service commercial',
        icon: Icons.handshake_outlined,
        items: [
          _ContactItemData(
            icon: Icons.email_outlined,
            entries: [
              _ContactLinkData(
                text: 'commercial@devnet.tn',
                uri: Uri(scheme: 'mailto', path: 'commercial@devnet.tn'),
              ),
            ],
          ),
          _ContactItemData(
            icon: Icons.phone_outlined,
            entries: [
              _ContactLinkData(
                text: '36 393 040',
                uri: Uri(scheme: 'tel', path: '36393040'),
              ),
              _ContactLinkData(
                text: '54 422 699',
                uri: Uri(scheme: 'tel', path: '54422699'),
              ),
              _ContactLinkData(
                text: '54 422 690',
                uri: Uri(scheme: 'tel', path: '54422690'),
              ),
              _ContactLinkData(
                text: '54 422 691',
                uri: Uri(scheme: 'tel', path: '54422691'),
              ),
            ],
          ),
        ],
      ),
      _ContactSectionData(
        title: 'Service Technique',
        icon: Icons.support_agent_outlined,
        items: [
          _ContactItemData(
            icon: Icons.email_outlined,
            entries: [
              _ContactLinkData(
                text: 'support@devnet.tn',
                uri: Uri(scheme: 'mailto', path: 'support@devnet.tn'),
              ),
            ],
          ),
          _ContactItemData(
            icon: Icons.phone_outlined,
            entries: [
              _ContactLinkData(
                text: '54 422 692',
                uri: Uri(scheme: 'tel', path: '54422692'),
              ),
              _ContactLinkData(
                text: '54 422 693',
                uri: Uri(scheme: 'tel', path: '54422693'),
              ),
              _ContactLinkData(
                text: '54 422 694',
                uri: Uri(scheme: 'tel', path: '54422694'),
              ),
            ],
          ),
        ],
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
      body: ModulePageContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Image.asset(
                    'assets/CU.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ..._sections
                  .map((section) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildContactSection(theme, section),
                      ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection(
    ThemeData theme,
    _ContactSectionData section,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  section.icon,
                  color: theme.colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(section.items.length, (index) {
            final item = section.items[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == section.items.length - 1 ? 0 : 20),
              child: _buildContactItem(theme, item),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactItem(ThemeData theme, _ContactItemData item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          alignment: Alignment.topCenter,
          child: Icon(
            item.icon,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(item.entries.length, (index) {
                final entry = item.entries[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == item.entries.length - 1 ? 0 : 8),
                  child: _buildContactEntry(theme, entry),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactEntry(ThemeData theme, _ContactLinkData entry) {
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.primary,
    );

    if (entry.uri == null) {
      return Text(
        entry.text,
        style: theme.textTheme.bodyLarge,
      );
    }

    return InkWell(
      onTap: () => _launchUri(entry.uri!),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          entry.text,
          style: baseStyle,
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

class _ContactSectionData {
  const _ContactSectionData({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_ContactItemData> items;
}

class _ContactItemData {
  const _ContactItemData({
    required this.icon,
    required this.entries,
  });

  final IconData icon;
  final List<_ContactLinkData> entries;
}

class _ContactLinkData {
  const _ContactLinkData({
    required this.text,
    this.uri,
  });

  final String text;
  final Uri? uri;
}
