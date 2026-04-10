import 'package:shared_preferences/shared_preferences.dart';

/// Локальный rate limit показов бюджетной строки в hero (скользящее окно).
class BudgetHeroRateLimitStore {
  BudgetHeroRateLimitStore(this._prefs);

  final SharedPreferences _prefs;

  /// Максимум показов за окно (на один budget id).
  static const int maxShowsPerWindow = 5;

  /// Скользящее окно учёта показов.
  static const Duration window = Duration(hours: 24);

  static const String _kPrefix = 'hero_budget_shows_v1_';

  List<int> _readMs(String budgetId) {
    final s = _prefs.getString('$_kPrefix$budgetId');
    if (s == null || s.isEmpty) return [];
    try {
      return s
          .split(',')
          .where((e) => e.isNotEmpty)
          .map(int.parse)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Уже достигнут лимит показов за [window].
  bool isRateLimited(String budgetId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowMs = window.inMilliseconds;
    final ts = _readMs(budgetId).where((t) => now - t <= windowMs).toList();
    return ts.length >= maxShowsPerWindow;
  }

  static const String _kGapSuffix = '_gap_ms';

  /// Минимум между двумя записями одного показа (защита от rebuild / sync).
  static const Duration minIntervalBetweenRecords = Duration(minutes: 2);

  /// Зафиксировать один показ бюджетного инсайта в hero.
  Future<void> recordShow(String budgetId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowMs = window.inMilliseconds;
    final ts = _readMs(budgetId).where((t) => now - t <= windowMs).toList()
      ..add(now);
    await _prefs.setString('$_kPrefix$budgetId', ts.join(','));
    await _prefs.setInt('$_kPrefix$budgetId$_kGapSuffix', now);
  }

  /// Учитывает показ, если с прошлой записи прошло не меньше [minIntervalBetweenRecords].
  /// Возвращает `true`, если в окно добавлен новый timestamp.
  Future<bool> recordShowIfGapped(String budgetId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final gapKey = '$_kPrefix$budgetId$_kGapSuffix';
    final last = _prefs.getInt(gapKey) ?? 0;
    if (now - last < minIntervalBetweenRecords.inMilliseconds) {
      return false;
    }
    await recordShow(budgetId);
    return true;
  }
}
