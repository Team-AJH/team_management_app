import '../models/group_member.dart';
import '../models/payment_instruction.dart';
import 'group_permissions_service.dart';

class PaymentInstructionService {
  final GroupPermissionsService _permissionsService =
      GroupPermissionsService();

  PaymentInstruction createPaymentInstruction({
    required GroupMember member,
    required String id,
    required String groupId,
    required PaymentPlatform platform,
    required String paymentLink,
    required String displayLabel,
  }) {
    _permissionsService.enforceCanManageGroup(member);

    final instruction = PaymentInstruction(
      id: id,
      ownerId: member.userId,
      groupId: groupId,
      platform: platform,
      paymentLink: paymentLink,
      displayLabel: displayLabel,
      isActive: true,
    );

    instruction.validate();
    return instruction;
  }

  String getQrCodeData(PaymentInstruction instruction) {
    instruction.validate();
    return instruction.paymentLink;
  }

  bool canViewPaymentInstruction(GroupMember member) {
    return member.isMember();
  }
}