import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Состояние «инсайт уже раскрыт» между экранами (без повторной задержки 220ms).
class InsightRevealSyncState {
  const InsightRevealSyncState({
    this.fingerprint,
    this.revealed = false,
  });

  /// См. [homeHeroRevealFingerprintForSync] в `home_insight_identity.dart`.
  final String? fingerprint;
  final bool revealed;
}

final insightRevealSyncProvider =
    StateProvider<InsightRevealSyncState>(
  (ref) => const InsightRevealSyncState(),
);
