import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTransaction(TransactionModel transaction) async {
    final collectionRef = _firestore
        .collection('groups')
        .doc(transaction.groupId)
        .collection('transactions');
    final docRef = collectionRef.doc();
    final newTransaction = TransactionModel(
      id: docRef.id,
      groupId: transaction.groupId,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      isCollection: transaction.isCollection,
      payerPayee: transaction.payerPayee,
      paymentLink: transaction.paymentLink,
    );
    await docRef.set(newTransaction.toMap());
  }

  Stream<List<TransactionModel>> getGroupTransactions(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<TransactionModel>> getRecentTransactions(String groupId, {int limit = 3}) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
