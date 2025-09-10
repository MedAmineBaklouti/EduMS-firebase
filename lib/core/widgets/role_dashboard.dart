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
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: cards,
      ),
    );
  }
}