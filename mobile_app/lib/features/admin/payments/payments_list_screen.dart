import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/num_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_bottom_sheet.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/financial_models.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/financials_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/widgets/log_expense_dialog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PaymentsListScreen extends ConsumerStatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  ConsumerState<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends ConsumerState<PaymentsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Hub'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Ledger Calendar'),
            Tab(text: 'Central Analytics'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CalendarTab(),
          _AnalyticsTab(),
          _ExpensesTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Ledger Calendar ───────────────────────────────────────────────────

class _CalendarTab extends ConsumerWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financialsControllerProvider);
    final ctrl = ref.read(financialsControllerProvider.notifier);

    final firstDay = DateTime(state.currentMonth.year, state.currentMonth.month, 1);
    final lastDay = DateTime(state.currentMonth.year, state.currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startOffset = firstDay.weekday - 1;

    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return RefreshIndicator(
      onRefresh: () => ctrl.loadCalendar(),
      child: state.isCalendarLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.paddingAll16,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => ctrl.changeMonth(-1),
                        icon: Icon(PhosphorIcons.caretLeft(), size: 20),
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(state.currentMonth),
                        style: AppText.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => ctrl.changeMonth(1),
                        icon: Icon(PhosphorIcons.caretRight(), size: 20),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weekDays.map((d) {
                      return Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: AppText.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: startOffset + daysInMonth,
                    itemBuilder: (context, index) {
                      if (index < startOffset) {
                        return const SizedBox.shrink();
                      }

                      final dayNum = index - startOffset + 1;
                      final dayDate = DateTime(
                        state.currentMonth.year,
                        state.currentMonth.month,
                        dayNum,
                      );

                      final df = state.dailyFinancials.firstWhere(
                        (f) =>
                            f.date.day == dayNum &&
                            f.date.month == state.currentMonth.month &&
                            f.date.year == state.currentMonth.year,
                        orElse: () => DailyFinancial(
                          date: dayDate,
                          earnings: 0,
                          expenses: 0,
                          net: 0,
                        ),
                      );

                      final isToday = DateUtils.isSameDay(DateTime.now(), dayDate);

                      return GestureDetector(
                        onTap: () => _showDayLedgerBottomSheet(context, dayDate, df, state.expenses),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.r12,
                            border: Border.all(
                              color: isToday ? AppColors.primary : AppColors.divider,
                              width: isToday ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                dayNum.toString(),
                                style: AppText.labelSmall.copyWith(
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isToday ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              if (df.earnings > 0)
                                Text(
                                  '+৳${df.earnings.toStringAsFixed(0)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (df.expenses > 0)
                                Text(
                                  '-৳${df.expenses.toStringAsFixed(0)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  void _showDayLedgerBottomSheet(
    BuildContext context,
    DateTime date,
    DailyFinancial df,
    List<Expense> allExpenses,
  ) {
    final dayExpenses = allExpenses.where((e) => DateUtils.isSameDay(e.spentAt, date)).toList();

    GymBottomSheet.show<void>(
      context: context,
      title: DateFormat('dd MMMM yyyy').format(date),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: AppSpacing.paddingAll16,
            decoration: BoxDecoration(
              color: df.net >= 0 
                  ? Colors.green.withValues(alpha: 0.08) 
                  : Colors.red.withValues(alpha: 0.08),
              borderRadius: AppSpacing.r16,
              border: Border.all(
                color: df.net >= 0 
                    ? Colors.green.withValues(alpha: 0.15) 
                    : Colors.red.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Balance',
                      style: AppText.labelSmall.copyWith(
                        color: df.net >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      df.net >= 0 ? 'Profit for today' : 'Loss for today',
                      style: AppText.bodySmall.copyWith(
                        color: df.net >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  df.net.toBDT(),
                  style: AppText.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: df.net >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          Container(
            padding: AppSpacing.paddingAll16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppSpacing.r16,
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIcons.trendUp(), color: Colors.green),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Revenue Collected', style: AppText.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Member Subscription Payments',
                        style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  df.earnings.toBDT(),
                  style: AppText.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Operational Expenses', style: AppText.titleMedium),
              Text(
                'Total: ${df.expenses.toBDT()}',
                style: AppText.labelSmall.copyWith(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          if (dayExpenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
              child: Text(
                'No operational expenses logged on this day.',
                style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayExpenses.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final exp = dayExpenses[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(exp.category),
                        color: _getCategoryColor(exp.category),
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exp.description,
                              style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              exp.category,
                              style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '- ${exp.amount.toBDT()}',
                        style: AppText.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Tab 2: Central Analytics ─────────────────────────────────────────────────

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financialsControllerProvider);
    final ctrl = ref.read(financialsControllerProvider.notifier);
    final report = state.centralReport;

    return RefreshIndicator(
      onRefresh: () => ctrl.loadReport(),
      child: SingleChildScrollView(
        padding: AppSpacing.paddingAll16,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Filter Pills
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.divider.withValues(alpha: 0.4),
                borderRadius: AppSpacing.r20,
              ),
              child: Row(
                children: [
                  _PeriodPill(
                    label: 'This Month',
                    isSelected: state.selectedPeriod == PeriodFilter.thisMonth,
                    onTap: () => ctrl.setPeriod(PeriodFilter.thisMonth),
                  ),
                  _PeriodPill(
                    label: 'Prev Month',
                    isSelected: state.selectedPeriod == PeriodFilter.prevMonth,
                    onTap: () => ctrl.setPeriod(PeriodFilter.prevMonth),
                  ),
                  _PeriodPill(
                    label: 'Custom Range',
                    isSelected: state.selectedPeriod == PeriodFilter.custom,
                    onTap: () => _pickCustomDateRange(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s12),

            // Custom Range Label Display
            if (state.selectedPeriod == PeriodFilter.custom &&
                state.customFrom != null &&
                state.customTo != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.calendarBlank(), size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('dd MMM').format(state.customFrom!)} – ${DateFormat('dd MMM yyyy').format(state.customTo!)}',
                        style: AppText.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _pickCustomDateRange(context, ref),
                        child: Text(
                          'Change',
                          style: AppText.labelSmall.copyWith(color: AppColors.primary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (state.isReportLoading)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.s40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (report == null)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.s40),
                child: Center(child: Text('No financials report loaded.')),
              )
            else ...[
              // Three Centralized Metrics Cards
              Row(
                children: [
                  Expanded(
                    child: _ReportMetricCard(
                      label: 'Collected Income',
                      amount: report.totalIncome,
                      icon: PhosphorIcons.trendUp(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: _ReportMetricCard(
                      label: 'Operational Costs',
                      amount: report.totalCost,
                      icon: PhosphorIcons.trendDown(),
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              _ReportMetricCard(
                label: 'Net Balance / Profit Margin',
                amount: report.netProfit,
                icon: PhosphorIcons.coins(),
                color: report.netProfit >= 0 ? AppColors.primary : AppColors.error,
                isWide: true,
                subtitle: report.totalIncome > 0
                    ? 'Margin: ${((report.netProfit / report.totalIncome) * 100).toStringAsFixed(1)}%'
                    : 'Margin: 0.0%',
              ),
              const SizedBox(height: AppSpacing.s24),

              // Interactive fl_chart Dual Curve
              Container(
                padding: AppSpacing.paddingAll16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.r24,
                  border: Border.all(color: AppColors.divider),
                ),
                child: _FinancialTimelineChart(timeline: report.timeline),
              ),
              const SizedBox(height: AppSpacing.s32),

              // Revenue Inflows Section
              Text('Revenue Inflow Breakdown', style: AppText.titleMedium),
              const SizedBox(height: AppSpacing.s12),
              GymCard(
                padding: AppSpacing.paddingAll16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inflows by Membership Plan', style: AppText.labelSmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.s16),
                    if (report.revenueByPlan.isEmpty)
                      Text('No subscription revenue recorded.', style: AppText.bodySmall.copyWith(color: AppColors.textHint))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: report.revenueByPlan.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s16),
                        itemBuilder: (context, i) {
                          final item = report.revenueByPlan[i];
                          final ratio = report.totalIncome > 0 ? item.totalAmount / report.totalIncome : 0.0;
                          return _BreakdownItem(
                            title: '${item.planName} (৳ ${item.planPrice.toStringAsFixed(0)})',
                            subtitle: '${item.transactionCount} subscriptions sold',
                            amount: item.totalAmount.toBDT(),
                            percentage: ratio,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    const SizedBox(height: AppSpacing.s24),
                    const Divider(),
                    const SizedBox(height: AppSpacing.s12),
                    Text('Inflows by Payment Method', style: AppText.labelSmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.s16),
                    if (report.revenueByMethod.isEmpty)
                      Text('No payments processed.', style: AppText.bodySmall.copyWith(color: AppColors.textHint))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: report.revenueByMethod.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s16),
                        itemBuilder: (context, i) {
                          final item = report.revenueByMethod[i];
                          final ratio = report.totalIncome > 0 ? item.totalAmount / report.totalIncome : 0.0;
                          return _BreakdownItem(
                            title: item.paymentMethod,
                            subtitle: '${item.transactionCount} payments processed',
                            amount: item.totalAmount.toBDT(),
                            percentage: ratio,
                            color: Colors.teal,
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s32),

              // Operational Outflows Section
              Text('Operational Outflow Breakdown', style: AppText.titleMedium),
              const SizedBox(height: AppSpacing.s12),
              GymCard(
                padding: AppSpacing.paddingAll16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outflows by Expense Category', style: AppText.labelSmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.s16),
                    if (report.expensesByCategory.isEmpty)
                      Text('No operational expenses recorded.', style: AppText.bodySmall.copyWith(color: AppColors.textHint))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: report.expensesByCategory.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s16),
                        itemBuilder: (context, i) {
                          final item = report.expensesByCategory[i];
                          final ratio = report.totalCost > 0 ? item.totalAmount / report.totalCost : 0.0;
                          return _BreakdownItem(
                            title: item.category,
                            subtitle: '${item.expenseCount} records logged',
                            amount: item.totalAmount.toBDT(),
                            percentage: ratio,
                            color: Colors.deepOrange,
                            icon: _getCategoryIcon(item.category),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s40),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomDateRange(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(financialsControllerProvider.notifier);
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
      helpText: 'Select Custom Ledger Period',
    );

    if (picked != null) {
      ctrl.setCustomRange(picked.start, picked.end);
    }
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: AppSpacing.r16,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.labelSmall.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isWide = false,
    this.subtitle,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isWide;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          amount.toBDT(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppText.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialTimelineChart extends StatelessWidget {
  const _FinancialTimelineChart({required this.timeline});
  final List<DailyFinancial> timeline;

  @override
  Widget build(BuildContext context) {
    // Calculate vertical scaling bounds across both metrics
    double maxVal = 10.0;
    for (final day in timeline) {
      if (day.earnings > maxVal) maxVal = day.earnings;
      if (day.expenses > maxVal) maxVal = day.expenses;
    }
    maxVal = maxVal * 1.15; // 15% headroom for padding

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daily Comparison', style: AppText.titleMedium),
            Row(
              children: [
                _ChartIndicator(label: 'Earnings', color: Colors.green),
                const SizedBox(width: 12),
                _ChartIndicator(label: 'Expenses', color: Colors.deepOrange),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        SizedBox(
          height: 180,
          child: timeline.isEmpty
              ? Center(
                  child: Text(
                    'No transaction timeline records for this range.',
                    style: AppText.bodySmall.copyWith(color: AppColors.textHint),
                  ),
                )
              : BarChart(
                  BarChartData(
                    maxY: maxVal,
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (timeline.length / 5).clamp(1.0, 10.0),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= timeline.length) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('dd MMM').format(timeline[index].date),
                                style: AppText.labelSmall.copyWith(fontSize: 8.5),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: timeline.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.earnings,
                            color: Colors.green.withValues(alpha: 0.85),
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: e.value.expenses,
                            color: Colors.deepOrange.withValues(alpha: 0.85),
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ChartIndicator extends StatelessWidget {
  const _ChartIndicator({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppText.labelSmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.percentage,
    required this.color,
    this.icon,
  });

  final String title;
  final String subtitle;
  final String amount;
  final double percentage;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.s8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: AppText.bodySmall.copyWith(color: AppColors.textHint)),
                ],
              ),
            ),
            Text(amount, style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppSpacing.rFull,
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ── Tab 3: Expenses Tracker ──────────────────────────────────────────────────

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financialsControllerProvider);
    final ctrl = ref.read(financialsControllerProvider.notifier);
    final summary = state.expensesSummary;

    return RefreshIndicator(
      onRefresh: () => ctrl.loadAll(),
      child: state.isExpensesLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.paddingAll16,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ExpenseSummaryCard(
                          label: 'Today',
                          amount: summary?.todayTotal ?? 0,
                          icon: PhosphorIcons.clock(),
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: _ExpenseSummaryCard(
                          label: 'Yesterday',
                          amount: summary?.yesterdayTotal ?? 0,
                          icon: PhosphorIcons.calendar(),
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _ExpenseSummaryCard(
                    label: 'This Month',
                    amount: summary?.monthTotal ?? 0,
                    icon: PhosphorIcons.calendarBlank(),
                    color: Colors.red,
                    isWide: true,
                  ),
                  const SizedBox(height: AppSpacing.s32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Logged Operations Ledger',
                        style: AppText.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () {
                          GymBottomSheet.show<void>(
                            context: context,
                            title: 'Log Operational Expense',
                            child: const LogExpenseDialog(),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.plus(), size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              const Text(
                                'Log Expense',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  if (state.expenses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s40),
                        child: Column(
                          children: [
                            Icon(PhosphorIcons.coins(), size: 48, color: AppColors.textHint),
                            const SizedBox(height: AppSpacing.s12),
                            Text(
                              'No operational expenses logged yet.\nTap "Log Expense" above to record water, bills, etc.',
                              textAlign: TextAlign.center,
                              style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.expenses.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final exp = state.expenses[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(exp.category).withValues(alpha: 0.1),
                                    borderRadius: AppSpacing.r12,
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(exp.category),
                                    color: _getCategoryColor(exp.category),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exp.description,
                                        style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            exp.category,
                                            style: AppText.bodySmall.copyWith(
                                              color: _getCategoryColor(exp.category),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('•', style: TextStyle(color: AppColors.textHint)),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('dd MMM, yyyy').format(exp.spentAt),
                                            style: AppText.bodySmall.copyWith(color: AppColors.textHint),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '- ${exp.amount.toBDT()}',
                                  style: AppText.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
    );
  }
}

class _ExpenseSummaryCard extends StatelessWidget {
  const _ExpenseSummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cardContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$label Expense',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amount.toBDT(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: AppSpacing.s8),
            Icon(
              PhosphorIcons.trendDown(),
              color: Colors.red.withValues(alpha: 0.5),
              size: 24,
            ),
          ],
        ],
      ),
    );

    return GymCard(
      padding: EdgeInsets.zero,
      child: cardContent,
    );
  }
}

// ── Helper Utilities ─────────────────────────────────────────────────────────

IconData _getCategoryIcon(String category) {
  switch (category) {
    case 'Water':
      return PhosphorIcons.drop();
    case 'Bill':
      return PhosphorIcons.lightning();
    case 'Salary':
      return PhosphorIcons.users();
    case 'Rent':
      return PhosphorIcons.house();
    case 'Maintenance':
      return PhosphorIcons.wrench();
    default:
      return PhosphorIcons.coins();
  }
}

Color _getCategoryColor(String category) {
  switch (category) {
    case 'Water':
      return Colors.blue;
    case 'Bill':
      return Colors.amber;
    case 'Salary':
      return Colors.teal;
    case 'Rent':
      return Colors.purple;
    case 'Maintenance':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}
