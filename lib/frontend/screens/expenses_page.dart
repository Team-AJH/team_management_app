import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../backend/repositories/group_repository.dart';
import '../../backend/repositories/transaction_repository.dart';
import '../../backend/models/transaction_model.dart';
import '../../backend/models/group.dart';
import 'payment_submission_page.dart';
import 'transaction_history_page.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view team expenses'));
    }

    final groupRepo = Provider.of<GroupRepository>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Payments',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Group>>(
              stream: groupRepo.getUserGroups(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final groups = snapshot.data ?? [];
                if (groups.isEmpty) {
                  return const Center(
                    child: Text(
                      'You are not part of any group yet.\nCreate or join a group to manage expenses.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _GroupExpensesCard(group: groups[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupExpensesCard extends StatelessWidget {
  final Group group;

  const _GroupExpensesCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final txnRepo = Provider.of<TransactionRepository>(context, listen: false);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (group.sportType.isNotEmpty)
                        Text(
                          group.sportType,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<TransactionModel>>(
                        stream: txnRepo.getGroupTransactions(group.id),
                        builder: (context, snapshot) {
                          double totalCollected = 0.0;
                          double totalExpenses = 0.0;

                          if (snapshot.hasData) {
                            for (var txn in snapshot.data!) {
                              if (txn.isCollection) {
                                totalCollected += txn.amount;
                              } else {
                                totalExpenses += txn.amount;
                              }
                            }
                          }

                          final balance = totalCollected - totalExpenses;
                          final isPositive = balance >= 0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Balance: ${isPositive ? "" : "-"}\$${balance.abs().toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: isPositive
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Collected: \$${totalCollected.toStringAsFixed(2)}  |  Expenses: \$${totalExpenses.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .doc(group.id)
                      .collection('members')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, memberSnap) {
                    bool isAdmin = false;
                    if (memberSnap.hasData && memberSnap.data!.exists) {
                      final role = memberSnap.data!.get('role') as String?;
                      isAdmin = role == 'admin';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            tooltip: 'Record Payment',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentSubmissionPage(groupId: group.id),
                              ),
                            ),
                          ),
                        if (group.paymentLink != null && group.paymentLink!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ElevatedButton.icon(
                              onPressed: () => _launchPaymentUrl(context, group.paymentLink!),
                              icon: const Icon(Icons.payment, size: 18),
                              label: const Text('Pay'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // ── Recent Transactions ─────────────────────────────────────────
          StreamBuilder<List<TransactionModel>>(
            stream: txnRepo.getRecentTransactions(group.id, limit: 3),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final recent = snapshot.data ?? [];

              if (recent.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'No transactions yet. Tap ＋ to record one.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  ...recent.map((txn) => _TransactionRow(txn: txn)),
                ],
              );
            },
          ),

          // ── View All button ─────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.history, size: 18),
              label: const Text('View All Transactions'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionHistoryPage(groupId: group.id),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Future<void> _launchPaymentUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch payment link.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid link: $e')),
        );
      }
    }
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel txn;
  const _TransactionRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final color = txn.isCollection ? Colors.green : Colors.red;
    final sign = txn.isCollection ? '+' : '-';
    final date = DateFormat('MMM d, yyyy').format(txn.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              txn.isCollection ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            '$sign\$${txn.amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
