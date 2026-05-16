import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'subscription_id') required String subscriptionId,
    required double amount,
    required String method,
    @JsonKey(name: 'paid_at') required DateTime paidAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}

@freezed
class PaymentSummary with _$PaymentSummary {
  const factory PaymentSummary({
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'payment_count') required int paymentCount,
    required String month,
  }) = _PaymentSummary;

  factory PaymentSummary.fromJson(Map<String, dynamic> json) =>
      _$PaymentSummaryFromJson(json);
}
