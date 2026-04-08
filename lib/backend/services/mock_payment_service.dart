import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import 'dart:math';

class MockPaymentService extends ChangeNotifier {
  // A list of mock transactions for the UI to display.
  final List<Transaction> _transactions = [
    Transaction(
      id: 'txn_1',
      title: 'Monthly Venue Fee',
      amount: 150.0,
      date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      isCollection: false,
      payerPayee: 'City Sports Center',
    ),
    Transaction(
      id: 'txn_2',
      title: 'Registration Dues',
      amount: 50.0,
      date: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      isCollection: true,
      payerPayee: 'Player 1',
    ),
    Transaction(
      id: 'txn_3',
      title: 'Equipment Purchase',
      amount: 220.50,
      date: DateTime.now().subtract(const Duration(days: 5, hours: 1)),
      isCollection: false,
      payerPayee: 'Sports Outlet',
    ),
  ];

  // We expose a copy of the list sorted by date ascending or descending
  List<Transaction> get transactions {
    final sorted = List<Transaction>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date)); // Descending by default
    return sorted;
  }
  
  double get totalCollected {
    return _transactions
        .where((t) => t.isCollection)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((t) => !t.isCollection)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get currentBalance => totalCollected - totalExpenses;

  // Simulate an async submission that validates UI structure properly
  Future<void> submitPayment(Transaction transaction) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Assign a new ID and current date if not provided properly (though model enforces it)
    final newTransaction = Transaction(
      id: 'txn_${Random().nextInt(10000)}',
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      isCollection: transaction.isCollection,
      payerPayee: transaction.payerPayee,
      paymentLink: transaction.paymentLink,
    );

    _transactions.add(newTransaction);
    notifyListeners();
  }
}
