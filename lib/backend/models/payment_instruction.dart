enum PaymentPlatform {
  venmo,
  paypal,
}

class PaymentInstruction {
  final String id;
  final String ownerId;
  final String groupId;
  final PaymentPlatform platform;
  final String paymentLink;
  final String displayLabel;
  final bool isActive;

  PaymentInstruction({
    required this.id,
    required this.ownerId,
    required this.groupId,
    required this.platform,
    required this.paymentLink,
    required this.displayLabel,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'groupId': groupId,
      'platform': platform.name,
      'paymentLink': paymentLink,
      'displayLabel': displayLabel,
      'isActive': isActive,
    };
  }

  factory PaymentInstruction.fromMap(Map<String, dynamic> map) {
    return PaymentInstruction(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      groupId: map['groupId'] ?? '',
      platform: PaymentPlatform.values.firstWhere(
        (p) => p.name == map['platform'],
        orElse: () => PaymentPlatform.venmo,
      ),
      paymentLink: map['paymentLink'] ?? '',
      displayLabel: map['displayLabel'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  void validate() {
    if (id.trim().isEmpty) {
      throw Exception('Payment instruction ID is required.');
    }

    if (ownerId.trim().isEmpty) {
      throw Exception('Owner ID is required.');
    }

    if (groupId.trim().isEmpty) {
      throw Exception('Group ID is required.');
    }

    if (paymentLink.trim().isEmpty) {
      throw Exception('Payment link cannot be empty.');
    }

    if (!_isValidExternalLink(paymentLink)) {
      throw Exception('Payment link must be a valid Venmo or PayPal URL.');
    }

    if (displayLabel.trim().isEmpty) {
      throw Exception('Display label is required.');
    }
  }

  bool _isValidExternalLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return false;
    }

    final host = uri.host.toLowerCase();

    if (platform == PaymentPlatform.venmo) {
      return host.contains('venmo.com');
    }

    if (platform == PaymentPlatform.paypal) {
      return host.contains('paypal.com') || host.contains('paypal.me');
    }

    return false;
  }
}