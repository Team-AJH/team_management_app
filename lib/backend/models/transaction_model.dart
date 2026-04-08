class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isCollection;
  final String? payerPayee;
  final String? paymentLink; // e.g. a link or QR code reference
  
  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isCollection,
    this.payerPayee,
    this.paymentLink,
  });

  // Example factory for future backend payload deserialization
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      isCollection: json['isCollection'] as bool,
      payerPayee: json['payerPayee'] as String?,
      paymentLink: json['paymentLink'] as String?,
    );
  }

  // Example serialization for future backend integration
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'isCollection': isCollection,
      'payerPayee': payerPayee,
      'paymentLink': paymentLink,
    };
  }
}
