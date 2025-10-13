import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings_title'.tr),
      ),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _Section(
              title: 'settings_section_primary'.tr,
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'settings_account'.tr,
                  subtitle: 'settings_account_subtitle'.tr,
                  onTap: controller.openAccount,
                ),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'settings_theme'.tr,
                  subtitle: controller.describeThemeMode(controller.themeMode),
                  trailing: _ThemeDropdown(controller: controller),
                ),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  title: 'settings_language'.tr,
                  subtitle: controller.describeLanguage(controller.language),
                  trailing: _LanguageDropdown(controller: controller),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'settings_section_more'.tr,
              children: [
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'settings_terms'.tr,
                  subtitle: 'settings_terms_subtitle'.tr,
                  onTap: () => _showInfoSheet(
                    context,
                    title: 'settings_terms_title'.tr,
                    body: 'settings_terms_body'.tr,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.headset_mic_outlined,
                  title: 'settings_support'.tr,
                  subtitle: 'settings_support_subtitle'.tr,
                  onTap: controller.openSupport,
                ),
                _SettingsTile(
                  icon: Icons.info_outlined,
                  title: 'settings_about'.tr,
                  subtitle: 'settings_about_subtitle'.tr,
                  onTap: () => _showInfoSheet(
                    context,
                    title: 'settings_about_title'.tr,
                    body: 'settings_about_body'.tr,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }

  void _showInfoSheet(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('settings_close'.tr),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
  });

  final String title;
  final List<_SettingsTile> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        foregroundColor: theme.colorScheme.primary,
        child: Icon(icon),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ThemeDropdown extends StatelessWidget {
  const _ThemeDropdown({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonHideUnderline(
      child: DropdownButton<ThemeMode>(
        value: controller.themeMode,
        alignment: Alignment.centerRight,
        onChanged: controller.updateThemeMode,
        items: controller.themeOptions
            .map(
              (mode) => DropdownMenuItem(
                value: mode,
                child: Text(controller.describeThemeMode(mode)),
              ),
            )
            .toList(),
        borderRadius: BorderRadius.circular(16),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonHideUnderline(
      child: DropdownButton<Locale>(
        value: controller.language,
        alignment: Alignment.centerRight,
        onChanged: controller.updateLanguage,
        items: controller.languageOptions
            .map(
              (locale) => DropdownMenuItem(
                value: locale,
                child: Text(controller.describeLanguage(locale)),
              ),
            )
            .toList(),
        borderRadius: BorderRadius.circular(16),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
