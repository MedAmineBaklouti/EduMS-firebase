import 'package:flutter/material.dart';
import '../../core/widgets/dashboard_card.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('$roleName Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final estimatedCount = (width / 220).floor();
          final crossAxisCount = estimatedCount <= 0
              ? 1
              : estimatedCount > 4
                  ? 4
                  : estimatedCount;
          final childAspectRatio = width >= 1000
              ? 1.25
              : width >= 700
                  ? 1.05
                  : 0.9;

          final subtitleStyle = Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Welcome back, $roleName!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose a feature to continue.',
                  style: subtitleStyle,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) => cards[index],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}