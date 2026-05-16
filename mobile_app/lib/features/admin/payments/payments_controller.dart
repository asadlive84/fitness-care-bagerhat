import 'package:fitness_care_bagerhat/core/api/api_exception.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'payments_controller.freezed.dart';

@freezed
class PaymentsState with _$PaymentsState {
  const factory PaymentsState({
    @Default([]) List<Payment> payments,
    PaymentSummary? summary,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(1) int page,
    @Default(false) bool hasMore,
    ApiException? error,
  }) = _PaymentsState;
}

class PaymentsController extends StateNotifier<PaymentsState> {
  PaymentsController({required PaymentRepository repository})
      : _repository = repository,
        super(const PaymentsState()) {
    load();
    loadSummary();
  }

  final PaymentRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, payments: [], isLoading: true, error: null);
    } else if (state.isLoadingMore || (state.page > 1 && !state.hasMore)) {
      return;
    } else {
      state = state.copyWith(
        isLoading: state.page == 1,
        isLoadingMore: state.page > 1,
        error: null,
      );
    }

    try {
      final response = await _repository.list(page: state.page);
      final newPayments = response.data ?? [];
      final hasMore = response.meta?.hasMore ?? false;

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        payments: refresh ? newPayments : [...state.payments, ...newPayments],
        hasMore: hasMore,
        page: state.page + 1,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e);
    }
  }

  Future<void> loadSummary() async {
    try {
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final summary = await _repository.getSummary(month: month);
      state = state.copyWith(summary: summary);
    } catch (_) {}
  }
}

final paymentsControllerProvider =
    StateNotifierProvider.autoDispose<PaymentsController, PaymentsState>((ref) {
  return PaymentsController(repository: ref.watch(paymentRepositoryProvider));
});
