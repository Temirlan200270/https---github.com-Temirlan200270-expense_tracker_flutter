import 'package:easy_localization/easy_localization.dart';
import 'package:features_analytics/features_analytics.dart';
import 'package:flutter/material.dart';

/// Тексты и акцент для [HomeHeroBlock] без дублирования разметки GlassCard.
class HomeDecisionHeroNarrative {
  const HomeDecisionHeroNarrative({
    required this.stateTitle,
    required this.microAction,
    required this.accentColor,
    this.detailLine,
  });

  final String stateTitle;
  final String microAction;
  final Color accentColor;

  /// Один сжатый вторичный смысл: синтез / лид инсайта / тренд.
  final String? detailLine;
}

class _SynthesisOutcome {
  const _SynthesisOutcome({
    this.text,
    this.suppressForecastExpensesLine = false,
  });

  final String? text;
  final bool suppressForecastExpensesLine;
}

/// Собирает нарратив главного героя из снимка Decision Engine.
class HomeDecisionHeroHelper {
  HomeDecisionHeroHelper._();

  static const int _kCriticalRunwayDays = 7;
  static const double _kSharpDeviationRatio = 1.45;

  static String _microActionTrKey(HomeFinancialStateTier tier) {
    return switch (tier) {
      HomeFinancialStateTier.stable => 'home.decision.micro_action_stable',
      HomeFinancialStateTier.caution => 'home.decision.micro_action_caution',
      HomeFinancialStateTier.danger => 'home.decision.micro_action_danger',
    };
  }

  static String _leadTrKey(
    HomeBehaviorInsight insight,
    TrendDirection trend,
  ) {
    final tier = switch (insight.confidence) {
      InsightConfidenceTier.high => 'high',
      InsightConfidenceTier.medium => 'medium',
      InsightConfidenceTier.low => 'low',
    };
    if (trend == TrendDirection.stable) {
      return insight.variant == HomeInsightVariant.overallOverspend
          ? 'home.decision.insight_overall_lead_$tier'
          : 'home.decision.insight_category_lead_$tier';
    }
    final suffix =
        trend == TrendDirection.accelerating ? 'accel' : 'slow';
    return insight.variant == HomeInsightVariant.overallOverspend
        ? 'home.decision.insight_overall_lead_${tier}_$suffix'
        : 'home.decision.insight_category_lead_${tier}_$suffix';
  }

  static _SynthesisOutcome _resolveSynthesis(
    HomeDecisionSnapshot snapshot,
    NumberFormat formatter,
  ) {
    final insight = snapshot.behaviorInsight;
    if (insight == null) {
      return const _SynthesisOutcome();
    }

    final runway = snapshot.runwayDays;
    if (runway == null) {
      final forecast = snapshot.forecast;
      if (forecast == null) {
        return const _SynthesisOutcome();
      }
      final amount = formatter.format(forecast.projectedExpenses);
      final trend = snapshot.spendingTrend;
      final isOverall =
          insight.variant == HomeInsightVariant.overallOverspend;
      final cat = insight.topContributor?.categoryName ?? '—';
      if (isOverall) {
        final key = switch (trend) {
          TrendDirection.accelerating =>
            'home.decision.synthesis_overall_forecast_accel',
          TrendDirection.slowing =>
            'home.decision.synthesis_overall_forecast_slow',
          TrendDirection.stable =>
            'home.decision.synthesis_overall_forecast_stable',
        };
        return _SynthesisOutcome(
          text: tr(key, namedArgs: {'amount': amount}),
          suppressForecastExpensesLine: true,
        );
      }
      final key = switch (trend) {
        TrendDirection.accelerating =>
          'home.decision.synthesis_category_forecast_accel',
        TrendDirection.slowing =>
          'home.decision.synthesis_category_forecast_slow',
        TrendDirection.stable =>
          'home.decision.synthesis_category_forecast_stable',
      };
      return _SynthesisOutcome(
        text: tr(key, namedArgs: {'amount': amount, 'category': cat}),
        suppressForecastExpensesLine: true,
      );
    }

    final days = '$runway';
    final trend = snapshot.spendingTrend;
    final ratio = insight.deviation.velocityRatio;
    final runwayFirst = runway <= _kCriticalRunwayDays;
    final deviationFirst =
        !runwayFirst && ratio >= _kSharpDeviationRatio;

    String trendBalancedKeyOverall() {
      return switch (trend) {
        TrendDirection.accelerating =>
          'home.decision.synthesis_overall_runway_accel',
        TrendDirection.slowing => 'home.decision.synthesis_overall_runway_slow',
        TrendDirection.stable => 'home.decision.synthesis_overall_runway_stable',
      };
    }

    String trendBalancedKeyCategory() {
      return switch (trend) {
        TrendDirection.accelerating =>
          'home.decision.synthesis_category_runway_accel',
        TrendDirection.slowing => 'home.decision.synthesis_category_runway_slow',
        TrendDirection.stable => 'home.decision.synthesis_category_runway_stable',
      };
    }

    String trendRunwayFirstKeyOverall() {
      return switch (trend) {
        TrendDirection.accelerating =>
          'home.decision.synthesis_overall_runway_first_accel',
        TrendDirection.slowing =>
          'home.decision.synthesis_overall_runway_first_slow',
        TrendDirection.stable =>
          'home.decision.synthesis_overall_runway_first_stable',
      };
    }

    String trendDeviationFirstKeyOverall() {
      return switch (trend) {
        TrendDirection.accelerating =>
          'home.decision.synthesis_overall_deviation_first_accel',
        TrendDirection.slowing =>
          'home.decision.synthesis_overall_deviation_first_slow',
        TrendDirection.stable =>
          'home.decision.synthesis_overall_deviation_first_stable',
      };
    }

    String trendRunwayFirstKeyCategory() {
      return switch (trend) {
        TrendDirection.accelerating =>
          'home.decision.synthesis_category_runway_first_accel',
        TrendDirection.slowing =>
          'home.decision.synthesis_category_runway_first_slow',
        TrendDirection.stable =>
          'home.decision.synthesis_category_runway_first_stable',
      };
    }

    String trendDeviationFirstKeyCategory() {
      return switch (trend) {
        TrendDirection.accelerating =>
          'home.decision.synthesis_category_deviation_first_accel',
        TrendDirection.slowing =>
          'home.decision.synthesis_category_deviation_first_slow',
        TrendDirection.stable =>
          'home.decision.synthesis_category_deviation_first_stable',
      };
    }

    final isOverall =
        insight.variant == HomeInsightVariant.overallOverspend;
    final cat = insight.topContributor?.categoryName ?? '—';

    if (isOverall) {
      if (runwayFirst) {
        return _SynthesisOutcome(
          text: tr(
            trendRunwayFirstKeyOverall(),
            namedArgs: {'days': days},
          ),
        );
      }
      if (deviationFirst) {
        return _SynthesisOutcome(
          text: tr(
            trendDeviationFirstKeyOverall(),
            namedArgs: {'days': days},
          ),
        );
      }
      return _SynthesisOutcome(
        text: tr(trendBalancedKeyOverall(), namedArgs: {'days': days}),
      );
    }

    if (runwayFirst) {
      return _SynthesisOutcome(
        text: tr(
          trendRunwayFirstKeyCategory(),
          namedArgs: {'days': days, 'category': cat},
        ),
      );
    }
    if (deviationFirst) {
      return _SynthesisOutcome(
        text: tr(
          trendDeviationFirstKeyCategory(),
          namedArgs: {'days': days, 'category': cat},
        ),
      );
    }
    return _SynthesisOutcome(
      text: tr(
        trendBalancedKeyCategory(),
        namedArgs: {'days': days, 'category': cat},
      ),
    );
  }

  /// Строит нарратив для объединённого hero-блока (баланс + состояние).
  static HomeDecisionHeroNarrative build({
    required ColorScheme colorScheme,
    required HomeDecisionSnapshot snapshot,
    required NumberFormat formatter,
  }) {
    final (Color accent, String stateKey) = switch (snapshot.stateTier) {
      HomeFinancialStateTier.stable => (
          colorScheme.primary,
          'home.decision.state_stable',
        ),
      HomeFinancialStateTier.caution => (
          colorScheme.tertiary,
          'home.decision.state_caution',
        ),
      HomeFinancialStateTier.danger => (
          colorScheme.error,
          'home.decision.state_danger',
        ),
    };

    final insight = snapshot.behaviorInsight;

    final synthesis = _resolveSynthesis(snapshot, formatter).text;

    String? detail;
    if (synthesis != null && synthesis.isNotEmpty) {
      detail = synthesis;
    } else if (insight != null) {
      detail = insight.variant == HomeInsightVariant.categoryFocus
          ? tr(
              _leadTrKey(insight, snapshot.spendingTrend),
              namedArgs: {
                'category': insight.topContributor?.categoryName ?? '—',
              },
            )
          : tr(_leadTrKey(insight, snapshot.spendingTrend));
    } else if (snapshot.spendingTrend == TrendDirection.accelerating ||
        snapshot.spendingTrend == TrendDirection.slowing) {
      detail = snapshot.spendingTrend == TrendDirection.accelerating
          ? tr('home.decision.trend_accelerating')
          : tr('home.decision.trend_slowing');
    }

    return HomeDecisionHeroNarrative(
      stateTitle: tr(stateKey),
      microAction: tr(_microActionTrKey(snapshot.stateTier)),
      accentColor: accent,
      detailLine: detail,
    );
  }
}
