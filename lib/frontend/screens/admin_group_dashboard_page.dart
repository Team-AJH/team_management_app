import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../backend/services/mock_payment_service.dart';

class AdminGroupDashboardPage extends StatelessWidget {
  final String groupName;

  const AdminGroupDashboardPage({
    super.key,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    // Mock user statistics for UI structure
    // In a real app, these would be fetched based on a groupId.
    const int totalUsers = 124;
    const int activePlayers = 108;

    return Scaffold(
      appBar: AppBar(
        title: Text('$groupName Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Summaries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Users',
                    value: totalUsers.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Active Players',
                    value: activePlayers.toString(),
                    icon: Icons.person_pin_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            Text(
              'Payment Summaries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<MockPaymentService>(
              builder: (context, paymentService, child) {
                // In a real app, the mock payment service might accept a groupId parameter
                // to filter the totals appropriately.
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Revenue',
                            value: '\$${paymentService.totalCollected.toStringAsFixed(2)}',
                            icon: Icons.account_balance_wallet,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Expenses',
                            value: '\$${paymentService.totalExpenses.toStringAsFixed(2)}',
                            icon: Icons.money_off,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Outstanding Dues',
                            value: '\$300.00', // Mock outstanding dues scoped to group
                            icon: Icons.warning_amber_rounded,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: SizedBox(), // Empty spacer for a nice layout
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
