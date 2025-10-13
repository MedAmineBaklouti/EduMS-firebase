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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSending = false;

  final Uri _emailUri = Uri(
    scheme: 'mailto',
    path: 'support@edums.school',
    query: 'subject=EduMS%20support%20request',
  );
  final Uri _phoneUri = Uri(scheme: 'tel', path: '+18001234567');
  final Uri _websiteUri = Uri.parse('https://www.edums.school/support');
  final Uri _chatUri = Uri.parse('https://wa.me/18001234567');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
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
              _buildHeroCard(theme),
              const SizedBox(height: 24),
              _buildSupportOptions(theme),
              const SizedBox(height: 32),
              _buildOfficeHoursCard(theme),
              const SizedBox(height: 32),
              _buildMessageForm(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: onPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.support_agent_outlined, color: onPrimary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We are here to help',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reach out to our support team with any questions about '
                      'EduMS. We usually respond within one business day.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOptions(ThemeData theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SupportOptionCard(
          icon: Icons.email_outlined,
          title: 'Email support',
          description: 'support@edums.school',
          actionLabel: 'Send email',
          color: theme.colorScheme.primary,
          onTap: () => _launchUri(_emailUri),
        ),
        _SupportOptionCard(
          icon: Icons.phone_in_talk_outlined,
          title: 'Call us',
          description: '+1 800 123 4567',
          actionLabel: 'Start call',
          color: theme.colorScheme.secondary,
          onTap: () => _launchUri(_phoneUri),
        ),
        _SupportOptionCard(
          icon: Icons.chat_bubble_outline,
          title: 'Live chat',
          description: 'Chat with a specialist on WhatsApp',
          actionLabel: 'Open chat',
          color: theme.colorScheme.tertiary,
          onTap: () => _launchUri(_chatUri),
        ),
        _SupportOptionCard(
          icon: Icons.public_outlined,
          title: 'Help center',
          description: 'Browse tutorials and FAQs online',
          actionLabel: 'Visit site',
          color: theme.colorScheme.error,
          onTap: () => _launchUri(_websiteUri),
        ),
      ],
    );
  }

  Widget _buildOfficeHoursCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.schedule_outlined,
                color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Office hours',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monday to Friday · 9:00 AM – 6:00 PM (GMT)',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Saturday · 10:00 AM – 2:00 PM (GMT)',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'We are closed on Sundays and public holidays. Messages '
                  'sent outside of these hours will receive a response the next '
                  'business day.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageForm(ThemeData theme) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: theme.colorScheme.primary.withOpacity(0.2),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send us a message',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your name, email, and details about how we can help. '
            'Our support team will reach out shortly after receiving your note.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full name',
              prefixIcon: const Icon(Icons.person_outline),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'How can we help?',
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.message_outlined),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSending ? null : _handleSendMessage,
              icon: _isSending
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_isSending ? 'Sending...' : 'Send message'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty || email.isEmpty || message.isEmpty) {
      Get.snackbar(
        'Add missing details',
        'Please share your name, email, and message so we can respond.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    });

    Get.snackbar(
      'Message queued',
      'Thanks for reaching out! Our support team will reply soon.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
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

class _SupportOptionCard extends StatelessWidget {
  const _SupportOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 300,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
