import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';

/// Financial metrics for a single plan over a given period.
class PlanFinancials {
  const PlanFinancials({
    required this.subscriptionsStarted,
    required this.totalBilled,
    required this.totalCollected,
    required this.totalDue,
  });

  final int subscriptionsStarted;
  final double totalBilled;
  final double totalCollected;
  final double totalDue;

  double get collectionRate =>
      totalBilled > 0 ? (totalCollected / totalBilled).clamp(0.0, 1.0) : 0.0;

  factory PlanFinancials.fromJson(Map<String, dynamic> j) => PlanFinancials(
        subscriptionsStarted: (j['subscriptions_started'] as num?)?.toInt() ?? 0,
        totalBilled: (j['total_billed'] as num?)?.toDouble() ?? 0.0,
        totalCollected: (j['total_collected'] as num?)?.toDouble() ?? 0.0,
        totalDue: (j['total_due'] as num?)?.toDouble() ?? 0.0,
      );

  static const zero = PlanFinancials(
    subscriptionsStarted: 0,
    totalBilled: 0,
    totalCollected: 0,
    totalDue: 0,
  );
}

/// A single active subscriber nested inside a plan.
class PlanSubscriberInfo {
  const PlanSubscriberInfo({
    required this.memberId,
    required this.memberName,
    required this.phone,
    required this.subscriptionPrice,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
    required this.moneyPaid,
    required this.moneyLeft,
  });

  final String memberId;
  final String memberName;
  final String phone;
  final double subscriptionPrice;
  final DateTime subscriptionStartDate;
  final DateTime subscriptionEndDate;
  final double moneyPaid;
  final double moneyLeft;

  factory PlanSubscriberInfo.fromJson(Map<String, dynamic> j) =>
      PlanSubscriberInfo(
        memberId: j['member_id'] as String,
        memberName: j['member_name'] as String,
        phone: j['phone'] as String,
        subscriptionPrice: (j['subscription_price'] as num).toDouble(),
        subscriptionStartDate:
            DateTime.parse(j['subscription_start_date'] as String),
        subscriptionEndDate:
            DateTime.parse(j['subscription_end_date'] as String),
        moneyPaid: (j['money_paid'] as num?)?.toDouble() ?? 0.0,
        moneyLeft: (j['money_left'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Plan template enriched with financials and active subscribers.
class PlanWithSubscribers {
  const PlanWithSubscribers({
    required this.plan,
    required this.financials,
    required this.subscribers,
  });

  final Plan plan;
  final PlanFinancials financials;
  final List<PlanSubscriberInfo> subscribers;

  factory PlanWithSubscribers.fromJson(Map<String, dynamic> j) =>
      PlanWithSubscribers(
        plan: Plan.fromJson(j),
        financials: j['financials'] != null
            ? PlanFinancials.fromJson(j['financials'] as Map<String, dynamic>)
            : PlanFinancials.zero,
        subscribers: (j['subscribers'] as List<dynamic>? ?? [])
            .map((e) =>
                PlanSubscriberInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Cross-plan aggregate totals.
class PlanSummary {
  const PlanSummary({
    required this.subscriptionsStarted,
    required this.totalBilled,
    required this.totalCollected,
    required this.totalDue,
  });

  final int subscriptionsStarted;
  final double totalBilled;
  final double totalCollected;
  final double totalDue;

  double get collectionRate =>
      totalBilled > 0 ? (totalCollected / totalBilled).clamp(0.0, 1.0) : 0.0;

  factory PlanSummary.fromJson(Map<String, dynamic> j) => PlanSummary(
        subscriptionsStarted:
            (j['subscriptions_started'] as num?)?.toInt() ?? 0,
        totalBilled: (j['total_billed'] as num?)?.toDouble() ?? 0.0,
        totalCollected: (j['total_collected'] as num?)?.toDouble() ?? 0.0,
        totalDue: (j['total_due'] as num?)?.toDouble() ?? 0.0,
      );

  static const zero =
      PlanSummary(subscriptionsStarted: 0, totalBilled: 0, totalCollected: 0, totalDue: 0);
}

/// Full API response shape.
class PlansApiResponse {
  const PlansApiResponse({
    required this.period,
    this.from,
    this.to,
    required this.summary,
    required this.plans,
  });

  final String period;
  final String? from;
  final String? to;
  final PlanSummary summary;
  final List<PlanWithSubscribers> plans;

  /// Parses the enriched format: `data` is `{filter, summary, plans: [...]}`.
  factory PlansApiResponse.fromJson(Map<String, dynamic> j) {
    final filter = j['filter'] as Map<String, dynamic>? ?? {};
    final summaryJson = j['summary'] as Map<String, dynamic>?;
    return PlansApiResponse(
      period: filter['period'] as String? ?? 'lifetime',
      from: filter['from'] as String?,
      to: filter['to'] as String?,
      summary: summaryJson != null
          ? PlanSummary.fromJson(summaryJson)
          : PlanSummary.zero,
      plans: (j['plans'] as List<dynamic>? ?? [])
          .map((e) => PlanWithSubscribers.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Parses the flat-list format: `data` is `[{plan, subscribers}, ...]`.
  ///
  /// The old backend format has no `financials` key per plan. This factory
  /// derives each plan's financials from its own `subscribers` list
  /// (subscription_price = billed, money_paid = collected, money_left = due).
  /// The overall summary is then the cross-plan aggregate of those values.
  factory PlansApiResponse.fromList(List<dynamic> list, {String period = 'monthly'}) {
    // Parse each plan; financials will be zero at this point (absent from JSON).
    final rawPlans = list
        .map((e) => PlanWithSubscribers.fromJson(e as Map<String, dynamic>))
        .toList();

    // Rebuild each plan with financials computed from its subscribers.
    final plans = rawPlans.map((p) {
      final billed    = p.subscribers.fold(0.0, (sum, s) => sum + s.subscriptionPrice);
      final collected = p.subscribers.fold(0.0, (sum, s) => sum + s.moneyPaid);
      final due       = (billed - collected).clamp(0.0, double.infinity);
      return PlanWithSubscribers(
        plan: p.plan,
        financials: PlanFinancials(
          subscriptionsStarted: p.subscribers.length,
          totalBilled: billed,
          totalCollected: collected,
          totalDue: due,
        ),
        subscribers: p.subscribers,
      );
    }).toList();

    // Cross-plan summary.
    double totalBilled = 0;
    double totalCollected = 0;
    int totalStarted = 0;
    for (final p in plans) {
      totalBilled    += p.financials.totalBilled;
      totalCollected += p.financials.totalCollected;
      totalStarted   += p.financials.subscriptionsStarted;
    }

    return PlansApiResponse(
      period: period,
      summary: PlanSummary(
        subscriptionsStarted: totalStarted,
        totalBilled: totalBilled,
        totalCollected: totalCollected,
        totalDue: (totalBilled - totalCollected).clamp(0, double.infinity),
      ),
      plans: plans,
    );
  }
}
