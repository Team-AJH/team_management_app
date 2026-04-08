import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../backend/services/mock_payment_service.dart';
import 'payment_submission_page.dart';
import 'transaction_history_page.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Payments',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentSubmissionPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Record Payment'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Consumer<MockPaymentService>(
            builder: (context, paymentService, child) {
              return Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Collected',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${paymentService.totalCollected.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Expenses',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${paymentService.totalExpenses.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionHistoryPage(),
                    ),
                  );
                },
                child: const Text('View Full History'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<MockPaymentService>(
               builder: (context, paymentService, child) {
                 final transactions = paymentService.transactions.take(5).toList(); // Show only top 5

                 if (transactions.isEmpty) {
                   return const Card(
                     child: Center(
                       child: Text('No recent transactions.'),
                     )
                   );
                 }

                 return Card(
                  child: ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final txn = transactions[index];
                      final dateFormatter = DateFormat('MMM d');
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: txn.isCollection 
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          child: Icon(
                            txn.isCollection ? Icons.arrow_downward : Icons.arrow_upward,
                            color: txn.isCollection ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(txn.title),
                        subtitle: Text(
                          txn.payerPayee != null ? (txn.isCollection ? 'From: ${txn.payerPayee}' : 'To: ${txn.payerPayee}') : dateFormatter.format(txn.date),
                        ),
                        trailing: Text(
                          '${txn.isCollection ? '+' : '-'}\$${txn.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: txn.isCollection ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                );
               } 
            ),
          ),
        ],
      ),
    );
  }
}
