import 'package:flutter/material.dart';

import 'dashboard_card.dart';
import 'modern_scaffold.dart';

class RoleDashboard extends StatelessWidget {
  final List<DashboardCard> cards;
  final String roleName;
  final VoidCallback onLogout;

  const RoleDashboard({
    super.key,
    required this.cards,
    required this.roleName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        title: Text('$roleName Dashboard'),
        actions: [
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _resolveCrossAxisCount(constraints.maxWidth);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Welcome back, $roleName',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose an area below to jump into your daily tasks.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => cards[index],
                    childCount: cards.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _resolveCrossAxisCount(double width) {
    if (width >= 1100) return 4;
    if (width >= 840) return 3;
    return 2;
  }
}
