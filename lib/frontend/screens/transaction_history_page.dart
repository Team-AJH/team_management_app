import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../backend/models/transaction_model.dart';
import '../../backend/repositories/transaction_repository.dart';

class TransactionHistoryPage extends StatelessWidget {
  final String groupId;

  const TransactionHistoryPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: Provider.of<TransactionRepository>(context, listen: false)
            .getGroupTransactions(groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final txn = transactions[index];
              return _buildTransactionTile(context, txn);
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel txn) {
    final dateFormatter = DateFormat('MMM d, yyyy  •  h:mm a');
    final amountStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: txn.isCollection ? Colors.green[700] : Colors.red[700],
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: txn.isCollection
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          txn.isCollection ? Icons.arrow_downward : Icons.arrow_upward,
          color: txn.isCollection ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        txn.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (txn.payerPayee != null && txn.payerPayee!.isNotEmpty)
            Text(
              txn.isCollection ? 'From: ${txn.payerPayee}' : 'To: ${txn.payerPayee}',
            ),
          Text(dateFormatter.format(txn.date), style: const TextStyle(fontSize: 12)),
          if (txn.paymentLink != null && txn.paymentLink!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.link, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    txn.paymentLink!,
                    style: const TextStyle(color: Colors.blue, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: Text(
        '${txn.isCollection ? '+' : '-'}\$${txn.amount.toStringAsFixed(2)}',
        style: amountStyle,
      ),
      isThreeLine: txn.paymentLink != null && txn.paymentLink!.isNotEmpty,
    );
  }
}
