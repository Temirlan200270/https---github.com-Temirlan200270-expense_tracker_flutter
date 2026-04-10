import 'package:features_analytics/features_analytics.dart';
import 'package:shared_models/shared_models.dart';

/// Резкое ухудшение состояния (stable→caution/danger и т.д.) — не держим 3s persistence.
bool homeFinancialSeverityIncreased(
  HomeFinancialStateTier? previous,
  HomeFinancialStateTier next,
) {
  if (previous == null) return false;
  const order = <HomeFinancialStateTier>[
    HomeFinancialStateTier.stable,
    HomeFinancialStateTier.caution,
    HomeFinancialStateTier.danger,
  ];
  return order.indexOf(next) > order.indexOf(previous);
}

/// Стабильность текста: не дергать UI при микро-изменениях формулировки.
bool uxCoreRoughlySame(String a, String b) {
  final nx = a.trim().toLowerCase();
  final ny = b.trim().toLowerCase();
  if (nx == ny) return true;
  if (nx.length < 6 || ny.length < 6) return false;
  final short = nx.length <= ny.length ? nx : ny;
  final long = nx.length > ny.length ? nx : ny;
  return long.contains(short) && short.length * 100 >= long.length * 65;
}

bool uxDecisionRoughlySame(UxDecisionView a, UxDecisionView b) {
  if (a.tone != b.tone) return false;
  return uxCoreRoughlySame(a.coreMessage, b.coreMessage);
}
