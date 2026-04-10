import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

/// Hero-карточка кошелька (подписи из l10n, опционально градиент по тону).
Widget homeWalletHeroCard({
  Key? key,
  required String? insightLine,
  String? insightContextLine,
  String? insightHintLine,
  double? budgetProgress,
  required String balanceAmountFormatted,
  required String expensesFormatted,
  required String incomeFormatted,
  required String forecastFormatted,
  bool isCompactFtue = false,
  List<Color>? gradientColors,
  WalletHeroContentOrder contentOrder = WalletHeroContentOrder.classic,
  IconData? insightLeadingIcon,
  Widget? footerCta,
}) {
  return WalletHeroCard(
    key: key,
    insightLine: insightLine,
    insightContextLine: insightContextLine,
    insightHintLine: insightHintLine,
    budgetProgress: budgetProgress,
    gradientColors: gradientColors,
    contentOrder: contentOrder,
    insightLeadingIcon: insightLeadingIcon,
    footerCta: footerCta,
    analysisSectionLabel: tr('home.hero.analysis_label'),
    totalBalanceLabel: tr('home.hero.total_balance'),
    balanceAmountFormatted: balanceAmountFormatted,
    expensesLabel: tr('home.hero.expenses_col'),
    expensesFormatted: expensesFormatted,
    incomeLabel: tr('home.hero.income_col'),
    incomeFormatted: incomeFormatted,
    forecastLabel: tr('home.hero.forecast_col'),
    forecastFormatted: forecastFormatted,
    isCompactFtue: isCompactFtue,
  );
}

/// Шапка главной: месяц, «Кошелёк», круглые кнопки (без разделительной линии).
class HomeWalletHeader extends StatelessWidget {
  const HomeWalletHeader({
    super.key,
    required this.topActions,
  });

  final Widget topActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final now = DateTime.now();
    final monthLine = DateFormat.yMMMM(
      context.locale.toLanguageTag(),
    ).format(now).toUpperCase();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLine,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('home.hero.wallet_title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          topActions,
        ],
      ),
    );
  }
}

/// Результат выбора инсайта для hero: текст, опциональный контекст, прогресс бюджета.
class HomeHeroInsightResult {
  const HomeHeroInsightResult({
    this.insightLine,
    this.insightContextLine,
    this.actionHint,
    this.budgetProgress,
    this.budgetEntityId,
  });

  final String? insightLine;

  /// Второй слой смысла (ситуация tier и т.п.) — только для UX-схлопывания, без метрик.
  final String? insightContextLine;

  /// Мягкая подсказка к поведению под основной CTA (без сырых метрик).
  final String? actionHint;

  final double? budgetProgress;

  /// Id бюджета для fingerprint (если инсайт с бюджета).
  final String? budgetEntityId;
}

bool _isBudgetHeroWarningRung(HomeBudgetPressure p) {
  return p.worstLineStatus != BudgetStatus.exceeded &&
      (p.worstLineStatus == BudgetStatus.warning ||
          p.aggregateUtilization >= 0.9);
}

String? _trimInsightLine(String? s) {
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}

/// Инсайт для hero: приоритет бюджет; иначе [UxDecisionView] (один смысл + контекст).
///
/// Если [unifiedHeroBudgetPressure] задан (поток SSS + [UxDecisionMapper.mapSnapshot]),
/// текст из [ux] не подменяется вторым бюджетным инсайтом из списка бюджетов.
HomeHeroInsightResult resolveHomeHeroInsight({
  required AsyncValue<List<BudgetWithSpending>> budgetsAsync,
  required UxDecisionView ux,
  required NumberFormat formatter,
  Set<String> softDeprioritizeBudgetIds = const {},
  Set<String> rateLimitedBudgetIds = const {},
  HomeBudgetPressure? unifiedHeroBudgetPressure,
}) {
  if (unifiedHeroBudgetPressure != null) {
    final p = unifiedHeroBudgetPressure;
    if (p.worstLineStatus == BudgetStatus.exceeded) {
      return HomeHeroInsightResult(
        insightLine: ux.coreMessage.trim().isEmpty ? null : ux.coreMessage.trim(),
        insightContextLine: _trimInsightLine(ux.contextLine),
        actionHint: ux.actionHint.trim().isEmpty ? null : ux.actionHint.trim(),
        budgetProgress: p.aggregateUtilization,
        budgetEntityId: p.primaryBudgetId,
      );
    }
    if (_isBudgetHeroWarningRung(p)) {
      return HomeHeroInsightResult(
        insightLine: ux.coreMessage.trim().isEmpty ? null : ux.coreMessage.trim(),
        insightContextLine: _trimInsightLine(ux.contextLine),
        actionHint: ux.actionHint.trim().isEmpty ? null : ux.actionHint.trim(),
        budgetProgress: p.aggregateUtilization,
        budgetEntityId: p.primaryBudgetId,
      );
    }
    return HomeHeroInsightResult(
      insightLine: ux.coreMessage.trim().isEmpty ? null : ux.coreMessage.trim(),
      insightContextLine: _trimInsightLine(ux.contextLine),
      actionHint: ux.actionHint.trim().isEmpty ? null : ux.actionHint.trim(),
      budgetProgress: null,
      budgetEntityId: null,
    );
  }

  final fromBudgets = budgetsAsync.maybeWhen(
    data: (list) {
      final b = pickBudgetForHeroInsight(
        list,
        softDeprioritizeBudgetIds: softDeprioritizeBudgetIds,
        rateLimitedBudgetIds: rateLimitedBudgetIds,
      );
      if (b != null) {
        return HomeHeroInsightResult(
          insightLine: formatHeroBudgetInsight(
            b: b,
            currencyFormatter: formatter,
          ),
          insightContextLine: null,
          actionHint: null,
          budgetProgress: b.progress,
          budgetEntityId: b.budget.id,
        );
      }
      return null;
    },
    orElse: () => null,
  );

  if (fromBudgets != null) return fromBudgets;

  final core = ux.coreMessage.trim();
  return HomeHeroInsightResult(
    insightLine: core.isEmpty ? null : core,
    insightContextLine: ux.contextLine?.trim().isNotEmpty == true
        ? ux.contextLine!.trim()
        : null,
    actionHint: ux.actionHint.trim().isEmpty ? null : ux.actionHint.trim(),
    budgetProgress: null,
  );
}

/// Строка инсайта по бюджету для hero (локализация с подстановками).
String? formatHeroBudgetInsight({
  required BudgetWithSpending b,
  required NumberFormat currencyFormatter,
}) {
  final name = b.categoryName ?? b.budget.name;
  final remainingMajor = b.remainingInCents / 100.0;
  final limitMajor = b.budget.limit.amount;
  final pct = (b.progress * 100).clamp(0, 999).round();
  return tr(
    'home.hero.budget_insight',
    namedArgs: {
      'name': name,
      'remaining': currencyFormatter.format(remainingMajor),
      'limit': currencyFormatter.format(limitMajor),
      'percent': '$pct',
    },
  );
}

/// Штраф к «весу» прогресса при негативном feedback по бюджетному инсайту.
const double kHeroBudgetFeedbackPenalty = 0.12;

double _heroBudgetAdjustedProgress(
  BudgetWithSpending b,
  Set<String> softDeprioritizeBudgetIds,
) {
  var p = b.progress;
  if (softDeprioritizeBudgetIds.contains(b.budget.id)) {
    p = (p - kHeroBudgetFeedbackPenalty).clamp(0.0, 1.0);
  }
  return p;
}

/// Убираем rate-limited id, только если остаётся хотя бы один кандидат.
List<BudgetWithSpending> _withoutRateLimitedIfPossible(
  List<BudgetWithSpending> list,
  Set<String> rateLimitedBudgetIds,
) {
  if (rateLimitedBudgetIds.isEmpty) return list;
  final filtered = list
      .where((b) => !rateLimitedBudgetIds.contains(b.budget.id))
      .toList();
  return filtered.isNotEmpty ? filtered : list;
}

/// Выбор бюджета для показа в hero: сначала с предупреждением / перерасходом.
BudgetWithSpending? pickBudgetForHeroInsight(
  List<BudgetWithSpending> list, {
  Set<String> softDeprioritizeBudgetIds = const {},
  Set<String> rateLimitedBudgetIds = const {},
}) {
  if (list.isEmpty) return null;
  var stressed =
      list.where((b) => b.isWarning || b.isOverBudget).toList();
  stressed =
      _withoutRateLimitedIfPossible(stressed, rateLimitedBudgetIds);
  if (stressed.isNotEmpty) {
    return stressed.reduce(
      (a, b) => _heroBudgetAdjustedProgress(a, softDeprioritizeBudgetIds) >=
              _heroBudgetAdjustedProgress(b, softDeprioritizeBudgetIds)
          ? a
          : b,
    );
  }
  var meaningful =
      list.where((b) => b.progress >= 0.15).toList();
  meaningful =
      _withoutRateLimitedIfPossible(meaningful, rateLimitedBudgetIds);
  if (meaningful.isEmpty) return null;
  return meaningful.reduce(
    (a, b) => _heroBudgetAdjustedProgress(a, softDeprioritizeBudgetIds) >=
            _heroBudgetAdjustedProgress(b, softDeprioritizeBudgetIds)
        ? a
        : b,
  );
}
