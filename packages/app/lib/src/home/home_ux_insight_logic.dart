import 'package:shared_models/shared_models.dart';

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

/// Ключ для записи feedback (день + tier + нормализованное начало текста).
String homeInsightFeedbackId({
  required UxDecisionView ux,
  required String tierName,
}) {
  final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final core = ux.coreMessage.trim();
  final head = core.length > 56 ? core.substring(0, 56) : core;
  return 'home_${tierName}_${day}_${head.hashCode.toUnsigned(32)}';
}
