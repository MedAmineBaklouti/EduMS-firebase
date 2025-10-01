import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/widgets/module_empty_state.dart';
import '../controllers/messaging_controller.dart';

class NewConversationView extends StatefulWidget {
  const NewConversationView({
    super.key,
    required this.controller,
    this.onClose,
  });

  final MessagingController controller;
  final VoidCallback? onClose;

  @override
  State<NewConversationView> createState() => _NewConversationViewState();
}

class _NewConversationViewState extends State<NewConversationView> {
  late final TextEditingController _searchController;
  String _query = '';
  String? _activeQuickFilterValue;

  MessagingController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final normalized = _searchController.text.toLowerCase().trim();
    setState(() {
      _query = normalized;
      if (_activeQuickFilterValue != null &&
          _activeQuickFilterValue != normalized) {
        _activeQuickFilterValue = null;
      }
    });
  }

  void _handleQuickFilterSelected(String filterValue) {
    final isActive = _activeQuickFilterValue == filterValue;
    setState(() {
      _activeQuickFilterValue = isActive ? null : filterValue;
    });

    final newText = isActive ? '' : filterValue;
    _searchController
      ..text = newText
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
  }

  Color _resolveRoleColor(ThemeData theme, String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
        return theme.colorScheme.primary;
      case 'parent':
        return theme.colorScheme.tertiary;
      case 'admin':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _resolveRoleLabel(String role) {
    if (role.isEmpty) {
      return 'Contact';
    }
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final quickFilters = <({String label, String value, IconData icon})>[
      (label: 'Teachers', value: 'teacher', icon: Icons.school_rounded),
      (label: 'Parents', value: 'parent', icon: Icons.family_restroom_rounded),
      (label: 'Administration', value: 'admin', icon: Icons.apartment_rounded),
    ];

    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Obx(() {
          final isLoading = _controller.isContactsLoading.value;
          final error = _controller.contactsError.value;
          final contacts = _controller.contacts;

          final filtered = _query.isEmpty
              ? contacts.toList()
              : contacts.where((contact) {
                  final name = contact.name.toLowerCase();
                  final role = contact.role.toLowerCase();
                  final relationship = contact.relationship?.toLowerCase() ?? '';
                  return name.contains(_query) ||
                      role.contains(_query) ||
                      relationship.contains(_query);
                }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primary.withOpacity(0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.messenger_outline_rounded,
                            size: 32,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search by name, role, or relationship to connect instantly.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            for (final filter in quickFilters)
                              FilterChip(
                                selected: _activeQuickFilterValue == filter.value,
                                onSelected: (_) =>
                                    _handleQuickFilterSelected(filter.value),
                                avatar: Icon(
                                  filter.icon,
                                  size: 18,
                                  color: _activeQuickFilterValue == filter.value
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onPrimaryContainer,
                                ),
                                label: Text(filter.label),
                                labelStyle: theme.textTheme.labelMedium?.copyWith(
                                  color: _activeQuickFilterValue == filter.value
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: theme.colorScheme.onPrimary
                                    .withOpacity(0.08),
                                selectedColor: theme.colorScheme.primary,
                                side: BorderSide(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.2),
                                ),
                                showCheckmark: false,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Material(
                    elevation: 4,
                    shadowColor: theme.shadowColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(28),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: 'Search contacts…',
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ModuleEmptyState(
                      icon: Icons.error_outline,
                      title: 'Unable to load contacts',
                      message: error,
                      actionLabel: 'Retry',
                      onAction: _controller.refreshContacts,
                    ),
                  ),
                )
              else if (contacts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ModuleEmptyState(
                      icon: Icons.people_outline,
                      title: 'No available contacts',
                      message:
                          'You currently do not have anyone to message based on your assignments.',
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ModuleEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches found',
                      message: 'Try searching with a different name or role.',
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final contact = filtered[index];
                      final accentColor = _resolveRoleColor(theme, contact.role);
                      final relationship = contact.relationship;
                      final initial = contact.name.isEmpty
                          ? '?'
                          : contact.name.characters.first.toUpperCase();

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () async {
                              await _controller
                                  .startConversationWithContact(contact);
                              widget.onClose?.call();
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color:
                                    theme.colorScheme.surfaceVariant.withOpacity(0.45),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: accentColor.withOpacity(0.18),
                                    foregroundColor: accentColor,
                                    child: Text(
                                      initial,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          contact.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Chip(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize.shrinkWrap,
                                              padding:
                                                  const EdgeInsets.symmetric(horizontal: 8),
                                              visualDensity: VisualDensity.compact,
                                              backgroundColor:
                                                  accentColor.withOpacity(0.14),
                                              label: Text(
                                                _resolveRoleLabel(contact.role),
                                                style: theme.textTheme.labelMedium?.copyWith(
                                                  color: accentColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (relationship != null &&
                                                relationship.isNotEmpty)
                                              Chip(
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                                visualDensity: VisualDensity.compact,
                                                backgroundColor: theme
                                                    .colorScheme.onSurfaceVariant
                                                    .withOpacity(0.12),
                                                label: Text(
                                                  relationship,
                                                  style: theme.textTheme.labelMedium?.copyWith(
                                                    color: theme
                                                        .colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        }),
      ),
    );
  }
}
