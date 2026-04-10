import '../providers/home_decision_engine_provider.dart';

/// Сегмент id для fingerprint (совпадает с префиксными запросами в БД).
String insightFingerprintIdSegment(String? raw) {
  if (raw == null || raw.isEmpty) return '_';
  return raw.replaceAll(RegExp(r'[^\w\-]'), '_');
}

/// Часовой бакет UTC для синхронизации раскрытия (`YYYYMMddHH`).
String homeInsightHourBucketUtc(DateTime utc) {
  final u = utc.toUtc();
  final y = u.year.toString().padLeft(4, '0');
  final mo = u.month.toString().padLeft(2, '0');
  final d = u.day.toString().padLeft(2, '0');
  final h = u.hour.toString().padLeft(2, '0');
  return '$y$mo$d$h';
}

/// Класс инсайта: версия + источник + область + severity (без текста строки).
///
/// [categoryOrBudgetScopeId]: id бюджета, id категории или `_` для «общего».
String homeInsightClassKeyV2({
  required bool fromBudget,
  required HomeInsightVariant? behaviorVariant,
  required String? categoryOrBudgetScopeId,
  required HomeFinancialStateTier tier,
}) {
  final seg = fromBudget
      ? 'b'
      : behaviorVariant == null
          ? 'n'
          : behaviorVariant == HomeInsightVariant.overallOverspend
              ? 'o'
              : 'c';
  final id = insightFingerprintIdSegment(categoryOrBudgetScopeId);
  return 'v2_${seg}_${id}_${tier.name}';
}

/// Ключ для cross-screen reveal sync (тот же класс + часовой срез).
String homeInsightRevealSyncKey({
  required String classKey,
  DateTime? utcNow,
}) {
  final u = (utcNow ?? DateTime.now()).toUtc();
  return '${classKey}_h${homeInsightHourBucketUtc(u)}';
}
