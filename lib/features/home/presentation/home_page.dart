import 'dart:async';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/ads/presentation/catdex_banner_ad_widget.dart';
import 'package:catdex/features/capture/data/supabase_cat_photo_storage_repository.dart';
import 'package:catdex/features/catdex/application/catdex_photo_recovery_service.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/presentation/catdex_page.dart';
import 'package:catdex/features/events/presentation/home_event_banner.dart';
import 'package:catdex/features/home/application/home_controller.dart';
import 'package:catdex/features/home/domain/entities/home_dashboard.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CatDexLocalizations.of(context);
    final dashboard = ref.watch(homeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            key: const ValueKey('home-profile-button'),
            tooltip: l10n.profileTitle,
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => context.pushNamed(AppRoute.profile.name),
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.pushNamed(AppRoute.settings.name),
          ),
        ],
      ),
      body: ListView(
        key: const Key('home_scroll_view'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          120,
        ),
        children: [
          HomeActiveEventSection(
            onOpen: (eventKey) => context.pushNamed(
              AppRoute.event.name,
              pathParameters: {'eventKey': eventKey},
            ),
          ),
          _SectionTitle(
            key: const Key('home_recent_discoveries_title'),
            title: l10n.recentDiscoveriesTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          _RecentDiscoveries(
            discoveries: dashboard.recentDiscoveries,
            onOpen: (discovery) => _openDiscovery(context, discovery),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PlayerHeader(dashboard: dashboard),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: l10n.dailyMissionsTitle),
          const SizedBox(height: AppSpacing.md),
          for (final mission in dashboard.dailyMissions) ...[
            _MissionTile(mission: mission),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          _SectionTitle(
            key: const Key('home_quick_actions_title'),
            title: l10n.quickActionsTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          const _QuickActions(),
          const CatDexBannerAdWidget(
            placementLog: 'CATDEX_AD_BANNER_PLACEMENT_HOME',
          ),
        ],
      ),
    );
  }

  void _openDiscovery(BuildContext context, RecentDiscovery discovery) {
    final entry = discovery.collectionEntry;
    if (entry == null) {
      return;
    }

    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => CatDexDetailPage(entry: entry),
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({required this.dashboard});

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: _softCardDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen,
            AppColors.skyBlue,
            AppColors.primaryPurple,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: AppColors.primaryPurple,
                    size: 40,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dashboard.playerName,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${l10n.playerLevelLabel} '
                        '${dashboard.playerProgress.level}',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.xpProgressLabel,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: dashboard.xpProgress,
                backgroundColor: AppColors.white.withValues(alpha: 0.28),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.warning,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${dashboard.playerProgress.totalXp} XP',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _Pill(
                  label: '${dashboard.pawPoints} ${l10n.pawPointsLabel}',
                  icon: Icons.stars_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _Pill(
              label:
                  '${l10n.completionLabel} '
                  '${(dashboard.collectionCompletion * 100).round()}%',
              icon: Icons.style_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission});

  final DailyMission mission;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final completed = mission.completed;
    final statusColor = completed ? AppColors.success : AppColors.warning;
    final statusLabel = completed
        ? l10n.completedLabel
        : l10n.notCompletedLabel;
    final missionStatus =
        '${mission.progress}/${mission.goal} • '
        '${mission.xpReward} XP • '
        '$statusLabel';

    return DecoratedBox(
      decoration: _softCardDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                completed ? Icons.check_circle_rounded : Icons.flag_rounded,
                color: statusColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _missionTitle(l10n, mission.titleKey),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    missionStatus,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _missionTitle(
    CatDexLocalizations l10n,
    DailyMissionTitleKey titleKey,
  ) {
    return switch (titleKey) {
      DailyMissionTitleKey.discoverOneCat => l10n.discoverOneCatMission,
      DailyMissionTitleKey.importOnePhoto => l10n.importOnePhotoMission,
      DailyMissionTitleKey.visitYourCatDex => l10n.visitCatDexMission,
    };
  }
}

class _RecentDiscoveries extends ConsumerWidget {
  const _RecentDiscoveries({required this.discoveries, required this.onOpen});

  final List<RecentDiscovery> discoveries;
  final ValueChanged<RecentDiscovery> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usesLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.15;

    return SizedBox(
      height: usesLargeText ? 336 : 316,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: discoveries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final discovery = discoveries[index];
          return _DiscoveryCard(
            discovery: discovery,
            resolveImage: () => _resolveHomeDiscoveryImage(ref, discovery),
            onTap: discovery.collectionEntry == null
                ? null
                : () => onOpen(discovery),
          );
        },
      ),
    );
  }
}

@visibleForTesting
Widget homeDiscoveryCardForTesting(
  RecentDiscovery discovery, {
  Future<CatDexResolvedImage> Function()? resolveImage,
  VoidCallback? onTap,
}) {
  return _DiscoveryCard(
    discovery: discovery,
    resolveImage:
        resolveImage ??
        () => CatDexImageResolver.resolveBestImagePath(
          discovery: discovery.collectionEntry?.discovery,
          discoveredPhotoPath: discovery.collectionEntry?.discoveredPhotoPath,
        ),
    onTap: onTap,
  );
}

class _DiscoveryCard extends StatefulWidget {
  const _DiscoveryCard({
    required this.discovery,
    required this.resolveImage,
    this.onTap,
  });

  final RecentDiscovery discovery;
  final Future<CatDexResolvedImage> Function() resolveImage;
  final VoidCallback? onTap;

  @override
  State<_DiscoveryCard> createState() => _DiscoveryCardState();
}

class _DiscoveryCardState extends State<_DiscoveryCard> {
  late Future<CatDexResolvedImage> _resolvedImage;
  String? _lastImageSourceLog;

  RecentDiscovery get discovery => widget.discovery;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _DiscoveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discovery != widget.discovery) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    final discoveryId =
        widget.discovery.collectionEntry?.discovery?.id ?? 'preview';
    debugPrint('CATDEX_HOME_CARD_DISCOVERY_ID $discoveryId');
    _lastImageSourceLog = null;
    _resolvedImage = widget.resolveImage();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final l10n = CatDexLocalizations.of(context);
    final rarityColor = _rarityColor(discovery.rarityName);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final usesLargeText = textScale > 1.15;
    final location = _meaningfulLocation(discovery.location);
    final speciesLabel = l10n.localizeDisplayValue(discovery.speciesName);
    final rarityLabel = l10n.localizeDisplayValue(discovery.rarityName);
    final variantLabel = l10n.localizeDisplayValue(discovery.variantName);

    return SizedBox(
      key: ValueKey(
        'home_discovery_card_'
        '${discovery.collectionEntry?.discovery?.id ?? discovery.catName}',
      ),
      width: usesLargeText ? 218 : 208,
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: rarityColor.withValues(alpha: 0.72),
            width: 1.5,
          ),
        ),
        elevation: 4,
        shadowColor: rarityColor.withValues(alpha: 0.2),
        child: InkWell(
          onTap: widget.onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: usesLargeText ? 55 : 57,
                    child: FutureBuilder<CatDexResolvedImage>(
                      future: _resolvedImage,
                      builder: (context, snapshot) {
                        return _buildImage(snapshot, colors, rarityColor);
                      },
                    ),
                  ),
                  Expanded(
                    flex: usesLargeText ? 45 : 43,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        usesLargeText ? 8 : 10,
                        12,
                        10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            discovery.catName,
                            key: const Key('home_discovery_name'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            speciesLabel,
                            key: const Key('home_discovery_species'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            key: const Key('home_discovery_badges'),
                            children: [
                              Flexible(
                                child: _DiscoveryBadge(
                                  label: rarityLabel,
                                  color: rarityColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: _DiscoveryBadge(
                                  label: variantLabel,
                                  color: colors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            key: const Key('home_discovery_bottom_row'),
                            children: [
                              if (location != null) ...[
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    location,
                                    key: const Key('home_discovery_location'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ] else
                                const Spacer(),
                              Text(
                                '${discovery.xpReward} XP',
                                key: const Key('home_discovery_xp'),
                                maxLines: 1,
                                style: textTheme.labelMedium?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImage(
    AsyncSnapshot<CatDexResolvedImage> snapshot,
    ColorScheme colors,
    Color rarityColor,
  ) {
    if (snapshot.hasError) {
      final error = snapshot.error;
      final signature = 'error|$error';
      if (_lastImageSourceLog != signature) {
        _lastImageSourceLog = signature;
        debugPrint(
          'CATDEX_HOME_CARD_IMAGE_ERROR '
          'id=${discovery.collectionEntry?.discovery?.id ?? 'preview'} '
          'resolver=$error',
        );
      }
    }
    if (snapshot.connectionState == ConnectionState.waiting &&
        snapshot.data == null) {
      _logImageSource('loading', null);
      return _HomeDiscoveryImagePlaceholder(
        loading: true,
        colorScheme: colors,
        rarityColor: rarityColor,
      );
    }

    final resolved = snapshot.data;
    if (resolved == null || resolved.type == CatDexResolvedImageType.none) {
      _logImageSource('placeholder', null);
      return _HomeDiscoveryImagePlaceholder(
        colorScheme: colors,
        rarityColor: rarityColor,
      );
    }

    final source = resolved.isLocalFile ? 'local' : 'network';
    final path = resolved.path ?? resolved.networkUrl;
    _logImageSource(source, path);
    return Image(
      key: const Key('home_discovery_photo'),
      image: resolved.provider!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (!resolved.isNetworkUrl || progress == null) {
          return child;
        }
        return _HomeDiscoveryImagePlaceholder(
          loading: true,
          colorScheme: colors,
          rarityColor: rarityColor,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          'CATDEX_HOME_CARD_IMAGE_ERROR '
          'id=${discovery.collectionEntry?.discovery?.id ?? 'preview'} '
          'source=${path ?? '-'} error=$error',
        );
        return _HomeDiscoveryImagePlaceholder(
          colorScheme: colors,
          rarityColor: rarityColor,
        );
      },
    );
  }

  void _logImageSource(String source, String? path) {
    final signature = '$source|${path ?? '-'}';
    if (_lastImageSourceLog == signature) {
      return;
    }
    _lastImageSourceLog = signature;
    debugPrint('CATDEX_HOME_CARD_IMAGE_SOURCE $source');
    debugPrint('CATDEX_HOME_CARD_IMAGE_PATH ${path ?? '-'}');
  }
}

class _HomeDiscoveryImagePlaceholder extends StatelessWidget {
  const _HomeDiscoveryImagePlaceholder({
    required this.colorScheme,
    required this.rarityColor,
    this.loading = false,
  });

  final ColorScheme colorScheme;
  final Color rarityColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: Key(
        loading
            ? 'home_discovery_image_loading'
            : 'home_discovery_image_placeholder',
      ),
      color: Color.alphaBlend(
        rarityColor.withValues(alpha: 0.12),
        colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: loading
            ? SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: rarityColor,
                ),
              )
            : Icon(
                Icons.pets_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                size: 46,
              ),
      ),
    );
  }
}

class _DiscoveryBadge extends StatelessWidget {
  const _DiscoveryBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.14),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.46)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

String? _meaningfulLocation(String? location) {
  final value = location?.trim();
  if (value == null || value.isEmpty || value == '-') {
    return null;
  }

  final normalized = value.toLowerCase();
  const rejectedValues = {
    'unknown',
    'sconosciuto',
    'non rilevato',
    'location unavailable',
  };
  if (rejectedValues.contains(normalized) ||
      normalized.contains('placeholder') ||
      normalized.startsWith('location_')) {
    return null;
  }
  return value;
}

Future<CatDexResolvedImage> _resolveHomeDiscoveryImage(
  WidgetRef ref,
  RecentDiscovery recent,
) {
  final entry = recent.collectionEntry;
  final discovery = entry?.discovery;
  return CatDexImageResolver.resolveBestImagePath(
    discovery: discovery,
    discoveredPhotoPath: entry?.discoveredPhotoPath,
    signedUrlForStoragePath: (path) => _createHomeSignedPhotoUrl(ref, path),
    cacheFileForStoragePath: discovery == null
        ? null
        : (path) => ref
              .read(catDexPhotoRecoveryServiceProvider)
              .recoverFromStorage(discovery: discovery, storagePath: path),
  );
}

Future<String?> _createHomeSignedPhotoUrl(
  WidgetRef ref,
  String storagePath,
) async {
  final trimmed = storagePath.trim();
  if (trimmed.isEmpty || trimmed == '-') {
    return null;
  }
  if (!ref.read(supabaseConfiguredProvider)) {
    return null;
  }

  try {
    return await ref
        .read(supabaseClientProvider)
        .storage
        .from(SupabaseCatPhotoStorageRepository.catPhotosBucketName)
        .createSignedUrl(trimmed, 60 * 60 * 24);
  } on Object catch (error) {
    debugPrint('CATDEX_HOME_CARD_IMAGE_ERROR signed_url $error');
    return null;
  }
}

Color _rarityColor(String rarityName) {
  return switch (rarityName.toLowerCase()) {
    'common' => AppColors.primaryGreen,
    'uncommon' => AppColors.skyBlue,
    'rare' => AppColors.primaryPurple,
    'epic' => const Color(0xFFEC4899),
    'legendary' => AppColors.warning,
    'mythic' => AppColors.danger,
    _ => AppColors.primaryGreen,
  };
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return Column(
      children: [
        _GradientActionButton(
          label: l10n.captureCatAction,
          icon: Icons.center_focus_strong_rounded,
          onPressed: () => context.goNamed(AppRoute.capture.name),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SecondaryActionButton(
          label: l10n.openCatDexAction,
          icon: Icons.style_rounded,
          onPressed: () => context.goNamed(AppRoute.catDex.name),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SecondaryActionButton(
          label: l10n.viewProfileAction,
          icon: Icons.person_rounded,
          onPressed: () => context.goNamed(AppRoute.profile.name),
        ),
      ],
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.primaryPurple],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _softCardDecoration({
  Color? color,
  Gradient? gradient,
}) {
  return BoxDecoration(
    color: color,
    gradient: gradient,
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
