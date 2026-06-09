import '../widgets/worldscore_header.dart';

/// Subscription tiers. GM is a strict superset of PRO (GM unlocks every PRO
/// feature plus the tournament/admin features). Tier is the single source of
/// truth for feature entitlement; it is persisted on the user doc as `tier`.
enum AppTier { pro, gm }

/// Individual capabilities that a tier can unlock. Tournament-related features
/// (tournaments/leaderboard/admin) are GM-only.
enum AppFeature {
  performance,
  personalRoundHistory,
  personalUpload,
  tournaments,
  leaderboard,
  admin,
}

/// Display + entitlement metadata for a tier. Edit this to tune pricing or
/// which features a tier unlocks.
class TierInfo {
  const TierInfo({
    required this.tier,
    required this.label,
    required this.monthlyPrice,
    required this.tagline,
    required this.features,
  });

  final AppTier tier;
  final String label;
  final String monthlyPrice; // display-only mock until a billing provider is wired in
  final String tagline;
  final Set<AppFeature> features;
}

/// The tier configuration. PRO = personal subset; GM = all features.
const Map<AppTier, TierInfo> tierConfigs = {
  AppTier.pro: TierInfo(
    tier: AppTier.pro,
    label: 'PRO',
    monthlyPrice: '\$9/mo',
    tagline: 'Track your own rounds, scores, and performance.',
    features: {
      AppFeature.performance,
      AppFeature.personalRoundHistory,
      AppFeature.personalUpload,
    },
  ),
  AppTier.gm: TierInfo(
    tier: AppTier.gm,
    label: 'GM',
    monthlyPrice: '\$29/mo',
    tagline: 'Everything in PRO, plus full tournament management.',
    features: {
      AppFeature.performance,
      AppFeature.personalRoundHistory,
      AppFeature.personalUpload,
      AppFeature.tournaments,
      AppFeature.leaderboard,
      AppFeature.admin,
    },
  ),
};

/// Resolves the stored tier for a user, falling back to the legacy `role`
/// field (`director` -> GM, anything else -> PRO) when `tier` is absent so
/// existing accounts keep working without a data migration.
AppTier tierFromStored({String? tier, String? role}) {
  switch (tier) {
    case 'gm':
      return AppTier.gm;
    case 'pro':
      return AppTier.pro;
  }
  return role == 'director' ? AppTier.gm : AppTier.pro;
}

extension AppTierX on AppTier {
  TierInfo get info => tierConfigs[this]!;
  String get label => info.label;
  String get monthlyPrice => info.monthlyPrice;

  bool has(AppFeature feature) => info.features.contains(feature);
  bool get hasTournamentAccess => has(AppFeature.tournaments);

  /// Dashboard a user lands on by default for this tier.
  WorldScoreRole get defaultMode =>
      this == AppTier.gm ? WorldScoreRole.gm : WorldScoreRole.pro;

  /// Legacy `role` string to persist alongside `tier` for back-compat.
  String get legacyRole => this == AppTier.gm ? 'director' : 'player';
}
