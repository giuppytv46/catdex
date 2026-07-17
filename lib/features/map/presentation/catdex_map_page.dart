import 'dart:async';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/location/application/discovery_location_capture_service.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_privacy_preferences.dart';
import 'package:catdex/features/location/domain/entities/location_service_result.dart';
import 'package:catdex/features/map/application/catdex_map_controller.dart';
import 'package:catdex/features/map/application/map_discovery_image_provider.dart';
import 'package:catdex/features/map/domain/entities/catdex_map_marker_data.dart';
import 'package:catdex/features/missions/application/daily_mission_controller.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class CatDexMapPage extends ConsumerStatefulWidget {
  const CatDexMapPage({this.tilesEnabled = true, super.key});

  /// Tests can disable network tiles while exercising markers and controls.
  final bool tilesEnabled;

  @override
  ConsumerState<CatDexMapPage> createState() => _CatDexMapPageState();
}

class _CatDexMapPageState extends ConsumerState<CatDexMapPage> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _discoveryViewportApplied = false;
  bool _lastKnownViewportApplied = false;

  @override
  void initState() {
    super.initState();
    debugPrint('CATDEX_MAP_OPENED');
    unawaited(_trackMapMission());
  }

  Future<void> _trackMapMission() async {
    try {
      await ref.read(dailyMissionControllerProvider.notifier).trackMapOpened();
    } on Object catch (error) {
      debugPrint(
        'CATDEX_MISSION_PROGRESS_TRACKING_SKIPPED '
        'reason=${error.runtimeType}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final preparation = ref.watch(catDexMapPreparationProvider);
    final unfilteredPreparation = ref.watch(
      catDexMapUnfilteredPreparationProvider,
    );
    final loadState = ref.watch(catDexMapLoadProvider);
    final currentPosition = ref.watch(mapCurrentPositionControllerProvider);
    final lastKnownLocation = ref.watch(catDexMapLastKnownLocationProvider);

    ref
      ..listen(catDexMapPreparationProvider, (_, next) {
        if (next.markers.isNotEmpty && !_discoveryViewportApplied) {
          _fitDiscoveriesWhenReady(next.markers, next.initialViewport);
          _discoveryViewportApplied = true;
        }
      })
      ..listen(mapCurrentPositionControllerProvider, (_, next) {
        final location = next.location;
        if (next.phase == MapCurrentPositionPhase.success && location != null) {
          _moveWhenReady(
            CatDexMapViewport(
              latitude: location.latitude!,
              longitude: location.longitude!,
              zoom: 15,
            ),
          );
        }
      });

    final lastKnown = switch (lastKnownLocation) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (preparation.markers.isEmpty &&
        !_lastKnownViewportApplied &&
        lastKnown?.hasValidCoordinates == true) {
      _lastKnownViewportApplied = true;
      _moveWhenReady(
        CatDexMapViewport(
          latitude: lastKnown!.latitude!,
          longitude: lastKnown.longitude!,
          zoom: 13,
        ),
      );
    }

    final initialViewport = preparation.initialViewport;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
        actions: [
          IconButton(
            key: const ValueKey('map-privacy-settings'),
            tooltip: l10n.mapLocationPreferences,
            onPressed: () => _showLocationPreferences(context),
            icon: const Icon(Icons.privacy_tip_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(
                  initialViewport.latitude,
                  initialViewport.longitude,
                ),
                initialZoom: initialViewport.zoom,
                minZoom: 3,
                maxZoom: 18,
                onMapReady: () {
                  _mapReady = true;
                  if (preparation.markers.isNotEmpty &&
                      !_discoveryViewportApplied) {
                    _discoveryViewportApplied = true;
                    _fitDiscoveries(
                      preparation.markers,
                      preparation.initialViewport,
                    );
                  }
                },
              ),
              children: [
                if (widget.tilesEnabled)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.giuppy.catdex',
                  )
                else
                  ColoredBox(color: Theme.of(context).colorScheme.surface),
                CatDexMapMarkerLayer(
                  markers: preparation.markers,
                  onMarkerTap: (marker) => _openPreview(context, marker),
                ),
                const _MapAttribution(),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: _MapTopControls(preparation: preparation),
          ),
          if (loadState.isLoading && unfilteredPreparation.markers.isEmpty)
            const Positioned.fill(child: _MapLoadingState()),
          if (loadState.hasError && unfilteredPreparation.markers.isEmpty)
            Positioned.fill(
              child: _MapErrorState(
                onRetry: () => ref.invalidate(catDexMapLoadProvider),
              ),
            ),
          if (!loadState.isLoading &&
              !loadState.hasError &&
              unfilteredPreparation.markers.isEmpty)
            Positioned.fill(
              child: CatDexMapEmptyState(
                onCapture: () => context.goNamed(AppRoute.capture.name),
                onPreferences: () => _showLocationPreferences(context),
              ),
            ),
          if (!loadState.isLoading &&
              !loadState.hasError &&
              unfilteredPreparation.markers.isNotEmpty &&
              preparation.markers.isEmpty)
            const Positioned(
              top: 112,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: 128,
              child: _MapFilterEmptyState(),
            ),
          Positioned(
            right: AppSpacing.md,
            bottom: 112 + MediaQuery.paddingOf(context).bottom,
            child: FloatingActionButton.small(
              key: const ValueKey('map-current-location'),
              tooltip: l10n.mapCenterCurrentLocation,
              onPressed:
                  currentPosition.phase == MapCurrentPositionPhase.requesting
                  ? null
                  : () => _requestCurrentLocation(context),
              child: currentPosition.phase == MapCurrentPositionPhase.requesting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }

  void _moveWhenReady(CatDexMapViewport viewport) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _moveTo(viewport);
    });
  }

  void _fitDiscoveriesWhenReady(
    List<CatDexMapMarkerData> markers,
    CatDexMapViewport fallbackViewport,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _fitDiscoveries(markers, fallbackViewport);
    });
  }

  void _fitDiscoveries(
    List<CatDexMapMarkerData> markers,
    CatDexMapViewport fallbackViewport,
  ) {
    if (markers.length < 2) {
      _moveTo(fallbackViewport);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [
          for (final marker in markers)
            LatLng(marker.latitude, marker.longitude),
        ],
        padding: const EdgeInsets.fromLTRB(48, 112, 48, 152),
        maxZoom: 14,
      ),
    );
  }

  void _moveTo(CatDexMapViewport viewport) {
    _mapController.move(
      LatLng(viewport.latitude, viewport.longitude),
      viewport.zoom,
    );
  }

  Future<void> _openPreview(
    BuildContext context,
    CatDexMapMarkerData marker,
  ) async {
    ref
        .read(selectedMapDiscoveryIdProvider.notifier)
        .select(marker.discoveryId);
    debugPrint('CATDEX_MAP_PREVIEW_OPENED id=${marker.discoveryId}');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CatDexMapDiscoveryPreview(
        discoveryId: marker.discoveryId,
      ),
    );
    if (mounted) {
      ref.read(selectedMapDiscoveryIdProvider.notifier).clear();
    }
  }

  Future<void> _requestCurrentLocation(BuildContext context) async {
    final l10n = CatDexLocalizations.of(context);
    final controller = ref.read(
      mapCurrentPositionControllerProvider.notifier,
    );
    final permission = await controller.permissionStatus();
    if (!context.mounted) return;

    if (permission == LocationPermissionStatus.permanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mapLocationPermissionPermanentlyDenied)),
      );
      await controller.requestCurrentPosition(
        allowPermissionRequest: false,
      );
      return;
    }

    var allowPermissionRequest = false;
    if (permission != LocationPermissionStatus.granted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.mapLocationPermissionRequired),
          content: Text(l10n.mapLocationPermissionExplanation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.mapAllowLocationAction),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (confirmed != true) return;
      allowPermissionRequest = true;
    }

    await controller.requestCurrentPosition(
      allowPermissionRequest: allowPermissionRequest,
    );
    if (!context.mounted) return;
    final result = ref.read(mapCurrentPositionControllerProvider);
    if (result.phase == MapCurrentPositionPhase.failure) {
      final message = switch (result.failureReason) {
        LocationFailureReason.permissionDeniedForever =>
          l10n.mapLocationPermissionPermanentlyDenied,
        LocationFailureReason.permissionDenied =>
          l10n.mapLocationPermissionRequired,
        _ => l10n.mapLocationUnavailable,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _showLocationPreferences(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const MapLocationPreferencesSheet(),
    );
  }
}

class CatDexMapMarkerLayer extends StatelessWidget {
  const CatDexMapMarkerLayer({
    required this.markers,
    required this.onMarkerTap,
    super.key,
  });

  final List<CatDexMapMarkerData> markers;
  final ValueChanged<CatDexMapMarkerData> onMarkerTap;

  @override
  Widget build(BuildContext context) {
    final mapMarkers = [
      for (final marker in markers)
        Marker(
          point: LatLng(marker.latitude, marker.longitude),
          width: 58,
          height: 58,
          child: GestureDetector(
            key: ValueKey('map-marker-${marker.discoveryId}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onMarkerTap(marker),
            child: _CatMapMarkerThumbnail(marker: marker),
          ),
        ),
    ];

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: mapMarkers,
        maxClusterRadius: 72,
        size: const Size(48, 48),
        builder: (context, clusterMarkers) {
          return DecoratedBox(
            key: ValueKey('map-cluster-${clusterMarkers.length}'),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x45000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${clusterMarkers.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 106),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '© OpenStreetMap contributors',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatMapMarkerThumbnail extends ConsumerWidget {
  const _CatMapMarkerThumbnail({required this.marker});

  final CatDexMapMarkerData marker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rarityColor = mapRarityColor(marker.discovery.rarity);
    final image = ref.watch(mapDiscoveryImageProvider(marker.discovery));
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        DecoratedBox(
          key: ValueKey('map-marker-thumbnail-${marker.discoveryId}'),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: rarityColor, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x42000000),
                blurRadius: 9,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: SizedBox.square(
                dimension: 43,
                child: image.when(
                  loading: () => const _MapMarkerImagePlaceholder(
                    loading: true,
                  ),
                  error: (error, _) {
                    debugPrint(
                      'CATDEX_MAP_MARKER_IMAGE_ERROR '
                      'id=${marker.discoveryId} error=$error',
                    );
                    return const _MapMarkerImagePlaceholder();
                  },
                  data: (resolved) {
                    final provider = resolved.provider;
                    if (provider == null) {
                      return const _MapMarkerImagePlaceholder();
                    }
                    return Image(
                      key: ValueKey('map-marker-image-${marker.discoveryId}'),
                      image: provider,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, _) {
                        debugPrint(
                          'CATDEX_MAP_MARKER_IMAGE_ERROR '
                          'id=${marker.discoveryId} error=$error',
                        );
                        return const _MapMarkerImagePlaceholder();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (marker.isApproximate)
          Positioned(
            right: -1,
            top: -1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.blur_circular_rounded,
                  color: AppColors.skyBlue,
                  size: 14,
                ),
              ),
            ),
          ),
        if (marker.hasEventArtwork)
          Positioned(
            right: -1,
            bottom: -1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: rarityColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.white,
                  size: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MapMarkerImagePlaceholder extends StatelessWidget {
  const _MapMarkerImagePlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: loading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.pets_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
      ),
    );
  }
}

class _MapTopControls extends StatelessWidget {
  const _MapTopControls({required this.preparation});

  final CatDexMapMarkerPreparation preparation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (preparation.markers.isNotEmpty) ...[
          _MapSummaryPill(preparation: preparation),
          const SizedBox(height: AppSpacing.sm),
        ],
        const _MapFilterChips(),
      ],
    );
  }
}

class _MapFilterChips extends ConsumerWidget {
  const _MapFilterChips();

  static const List<CatRarity> _filterRarities = [
    CatRarity.common,
    CatRarity.uncommon,
    CatRarity.rare,
    CatRarity.epic,
    CatRarity.legendary,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CatDexLocalizations.of(context);
    final filters = ref.watch(catDexMapFiltersProvider);
    final controller = ref.read(catDexMapFiltersProvider.notifier);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 12),
        ],
      ),
      child: SizedBox(
        height: 48,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          scrollDirection: Axis.horizontal,
          children: [
            Center(
              child: ChoiceChip(
                key: const ValueKey('map-filter-all'),
                label: Text(l10n.mapFilterAll),
                selected: !filters.isActive,
                onSelected: (_) => controller.clear(),
              ),
            ),
            for (final rarity in _filterRarities) ...[
              const SizedBox(width: AppSpacing.xs),
              Center(
                child: FilterChip(
                  key: ValueKey('map-filter-${rarity.name}'),
                  label: Text(l10n.rarityName(rarity.name)),
                  selected: filters.rarities.contains(rarity),
                  avatar: Icon(
                    Icons.circle,
                    size: 11,
                    color: mapRarityColor(rarity),
                  ),
                  onSelected: (_) => controller.toggleRarity(rarity),
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.xs),
            Center(
              child: FilterChip(
                key: const ValueKey('map-filter-event'),
                label: Text(l10n.mapFilterEvent),
                selected: filters.eventOnly,
                avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                onSelected: (_) => controller.toggleEventOnly(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSummaryPill extends StatelessWidget {
  const _MapSummaryPill({required this.preparation});

  final CatDexMapMarkerPreparation preparation;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    if (preparation.markers.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 12),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            preparation.missingLocationCount == 0
                ? l10n.mapLocatedDiscoveryCount(preparation.markers.length)
                : l10n.mapMissingLocationCount(
                    preparation.missingLocationCount,
                  ),
            maxLines: 2,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapFilterEmptyState extends StatelessWidget {
  const _MapFilterEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x26000000), blurRadius: 12),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.mapNoFilterResults,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CatDexMapEmptyState extends StatelessWidget {
  const CatDexMapEmptyState({
    required this.onCapture,
    required this.onPreferences,
    super.key,
  });

  final VoidCallback onCapture;
  final VoidCallback onPreferences;

  @override
  Widget build(BuildContext context) {
    debugPrint('CATDEX_MAP_EMPTY_STATE');
    final l10n = CatDexLocalizations.of(context);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          112,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 58,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.mapEmptyTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.mapEmptyMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(l10n.mapOpenCapture),
                ),
                TextButton.icon(
                  onPressed: onPreferences,
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: Text(l10n.mapLocationPreferences),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapLoadingState extends StatelessWidget {
  const _MapLoadingState();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _MapErrorState extends StatelessWidget {
  const _MapErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 52),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.mapLoadError,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(l10n.retryAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CatDexMapDiscoveryPreview extends ConsumerWidget {
  const CatDexMapDiscoveryPreview({
    required this.discoveryId,
    this.onOpenDiscovery,
    super.key,
  });

  final String discoveryId;
  final ValueChanged<String>? onOpenDiscovery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = _discoveryById(
      ref.watch(localDiscoverySessionProvider),
      discoveryId,
    );
    if (discovery == null) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = CatDexLocalizations.of(context);
    final display = const CatDisplayFormatter().fromDiscovery(discovery);
    final location = discovery.captureLocation;
    final image = ref.watch(mapDiscoveryImageProvider(discovery));
    final artwork = _preferredArtworkForDiscovery(
      ref.watch(catCardCollectionProvider),
      discovery.id,
    );
    final date = MaterialLocalizations.of(
      context,
    ).formatCompactDate(discovery.discoveredAt.toLocal());

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    display.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.mapRemoveLocation,
                  onPressed: () => _removeLocation(context, ref),
                  icon: const Icon(Icons.location_off_outlined),
                ),
              ],
            ),
            Text(
              l10n.localizeDisplayValue(display.displaySpecies),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: _RarityChip(rarity: discovery.rarity),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MapPreviewMedia(
                    label: l10n.mapPhotoLabel,
                    child: image.when(
                      loading: _MapPhotoPlaceholder.loading,
                      error: (_, _) => const _MapPhotoPlaceholder(),
                      data: (resolved) => _MapResolvedPhoto(
                        resolved: resolved,
                        discoveryId: discovery.id,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MapPreviewMedia(
                    label: l10n.mapArtworkLabel,
                    child: artwork == null
                        ? _MapArtworkPlaceholder(
                            message: l10n.mapArtworkUnavailable,
                          )
                        : _MapArtworkImage(card: artwork),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _PreviewInfoRow(
              icon: Icons.calendar_today_outlined,
              text: '${l10n.discoveredOnLabel}: $date',
            ),
            if (location?.hasPlaceDetails == true)
              _PreviewInfoRow(
                icon: Icons.place_outlined,
                text: location!.displayLabel,
              ),
            if (location?.isApproximate == true)
              _PreviewInfoRow(
                icon: Icons.blur_circular_outlined,
                text: l10n.mapApproximateLocation,
              ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const ValueKey('map-open-catdex-detail'),
              onPressed: () => _openDiscovery(context),
              icon: const Icon(Icons.pets_rounded),
              label: Text(l10n.mapOpenInCatDex),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeLocation(BuildContext context, WidgetRef ref) async {
    final l10n = CatDexLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.mapRemoveLocation),
        content: Text(l10n.mapRemoveLocationConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.mapRemoveAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await ref
        .read(catDexMapActionsProvider)
        .removeLocation(discoveryId);
    if (removed && context.mounted) Navigator.pop(context);
  }

  void _openDiscovery(BuildContext context) {
    debugPrint('CATDEX_MAP_DISCOVERY_OPENED id=$discoveryId');
    final callback = onOpenDiscovery;
    if (callback != null) {
      callback(discoveryId);
      return;
    }
    Navigator.pop(context);
    unawaited(
      context.pushNamed(
        AppRoute.discoveryDetail.name,
        pathParameters: {'discoveryId': discoveryId},
      ),
    );
  }
}

class _MapResolvedPhoto extends StatelessWidget {
  const _MapResolvedPhoto({
    required this.resolved,
    required this.discoveryId,
  });

  final CatDexResolvedImage resolved;
  final String discoveryId;

  @override
  Widget build(BuildContext context) {
    final provider = resolved.provider;
    if (provider == null) return const _MapPhotoPlaceholder();
    return Image(
      image: provider,
      fit: BoxFit.cover,
      errorBuilder: (_, error, _) {
        debugPrint(
          'CATDEX_MAP_PREVIEW_IMAGE_ERROR id=$discoveryId error=$error',
        );
        return const _MapPhotoPlaceholder();
      },
    );
  }
}

class _MapPreviewMedia extends StatelessWidget {
  const _MapPreviewMedia({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AspectRatio(
          aspectRatio: 1.15,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _MapArtworkImage extends StatelessWidget {
  const _MapArtworkImage({required this.card});

  final CatCardRecord card;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Image.network(
      card.finalCardUrl,
      key: ValueKey('map-artwork-${card.cardId}'),
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : const _MapPhotoPlaceholder.loading(),
      errorBuilder: (_, error, _) {
        debugPrint(
          'CATDEX_MAP_ARTWORK_IMAGE_ERROR cardId=${card.cardId} error=$error',
        );
        return _MapArtworkPlaceholder(message: l10n.mapArtworkUnavailable);
      },
    );
  }
}

class _MapArtworkPlaceholder extends StatelessWidget {
  const _MapArtworkPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPhotoPlaceholder extends StatelessWidget {
  const _MapPhotoPlaceholder();

  const _MapPhotoPlaceholder.loading();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.pets_rounded, color: AppColors.primaryPurple),
      ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({required this.rarity});

  final CatRarity rarity;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final normalized = rarity == CatRarity.mythic ? 'legendary' : rarity.name;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: mapRarityColor(rarity).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mapRarityColor(rarity)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          l10n.rarityName(normalized),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PreviewInfoRow extends StatelessWidget {
  const _PreviewInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, maxLines: 2)),
        ],
      ),
    );
  }
}

class MapLocationPreferencesSheet extends ConsumerStatefulWidget {
  const MapLocationPreferencesSheet({super.key});

  @override
  ConsumerState<MapLocationPreferencesSheet> createState() =>
      _MapLocationPreferencesSheetState();
}

class _MapLocationPreferencesSheetState
    extends ConsumerState<MapLocationPreferencesSheet> {
  LocationPrivacyPreferences? _preferences;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final preferences = await ref
        .read(locationPrivacyPreferencesRepositoryProvider)
        .getPreferences();
    if (!mounted) return;
    setState(() => _preferences = preferences);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final preferences = _preferences;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: preferences == null
          ? const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.mapLocationPreferences,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.mapLocationPreferencesMessage),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: preferences.locationCollectionEnabled,
                  title: Text(l10n.mapSaveDiscoveryLocation),
                  onChanged: (value) {
                    setState(() {
                      _preferences = preferences.copyWith(
                        locationCollectionEnabled: value,
                        rememberLocationChoice: true,
                        locationConsentVersion: value ? 'map-v1' : null,
                      );
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<LocationPrecisionMode>(
                  segments: [
                    ButtonSegment(
                      value: LocationPrecisionMode.approximate,
                      label: Text(l10n.mapApproximateLocation),
                      icon: const Icon(Icons.blur_circular_outlined),
                    ),
                    ButtonSegment(
                      value: LocationPrecisionMode.precise,
                      label: Text(l10n.mapPreciseLocation),
                      icon: const Icon(Icons.gps_fixed_rounded),
                    ),
                  ],
                  selected: {preferences.locationPrecisionMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _preferences = preferences.copyWith(
                        locationPrecisionMode: selection.single,
                      );
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.saveChangesAction),
                ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    final preferences = _preferences;
    if (preferences == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(locationPrivacyPreferencesRepositoryProvider)
          .savePreferences(preferences);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

CatDiscovery? _discoveryById(
  List<CatDiscovery> discoveries,
  String discoveryId,
) {
  for (final discovery in discoveries) {
    if (discovery.id == discoveryId) return discovery;
  }
  return null;
}

CatCardRecord? _preferredArtworkForDiscovery(
  List<CatCardRecord> cards,
  String discoveryId,
) {
  final completed = cards
      .where((card) => card.discoveryId == discoveryId && card.isCompleted)
      .toList(growable: false);
  for (final card in completed) {
    if (card.cardType == CatCardType.normal) return card;
  }
  if (completed.isEmpty) return null;
  completed.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return completed.first;
}

Color mapRarityColor(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => AppColors.primaryGreen,
    CatRarity.uncommon => const Color(0xFF22D3EE),
    CatRarity.rare => const Color(0xFF3B82F6),
    CatRarity.epic => const Color(0xFF8B5CF6),
    CatRarity.legendary || CatRarity.mythic => const Color(0xFFF4C542),
  };
}
