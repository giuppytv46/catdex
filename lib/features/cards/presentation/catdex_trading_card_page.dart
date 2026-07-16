import 'dart:async';
import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/ads/presentation/catdex_banner_ad_widget.dart';
import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/cards/application/card_generation_state_controller.dart';
import 'package:catdex/features/cards/application/cat_card_legacy_migration.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/presentation/card_image_cache_buster.dart';
import 'package:catdex/features/cards/presentation/widgets/card_generation_status_panel.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CardGenerationCallback = Future<String?> Function();

const String _cardGenerationPendingLabel = 'Creazione della carta in corso…';
const String _cardGenerationLongWaitLabel =
    'La creazione sta richiedendo più tempo del previsto, '
    'ma è ancora in corso.';
const Duration _cardGenerationLongWaitThreshold = Duration(seconds: 20);

class CatDexTradingCardPage extends ConsumerStatefulWidget {
  const CatDexTradingCardPage({
    String? discoveryId,
    this.cardId,
    int? collectionNumber,
    CatDexCollectionEntry? entry,
    this.cacheBustVersion,
    this.onGenerate,
    this.onRegenerate,
    super.key,
  }) : assert(
         discoveryId != null || entry != null,
         'Provide a discoveryId or an initial entry.',
       ),
       discoveryId = discoveryId ?? '',
       collectionNumber = collectionNumber ?? 0,
       initialEntry = entry;

  final String discoveryId;
  final String? cardId;
  final int collectionNumber;
  final CatDexCollectionEntry? initialEntry;
  final int? cacheBustVersion;
  final CardGenerationCallback? onGenerate;
  final CardGenerationCallback? onRegenerate;

  @override
  ConsumerState<CatDexTradingCardPage> createState() =>
      _CatDexTradingCardPageState();
}

class _CatDexTradingCardPageState extends ConsumerState<CatDexTradingCardPage> {
  CatDiscovery? _discovery;
  CatCardRecord? _cardRecord;
  int? _localCacheBustVersion;
  bool _repositoryLoading = true;
  bool _entityMissing = false;
  bool _imageLoadFailed = false;
  bool _imageLoadingLogged = false;
  bool _disposed = false;
  bool _backRequested = false;
  bool _backCompletedLogged = false;
  int _loadRequestToken = 0;
  CardGenerationSharedPhase? _lastLoggedSharedPhase;
  Timer? _longWaitTimer;

  @override
  void initState() {
    super.initState();
    _discovery = widget.initialEntry?.discovery;
    _cardRecord = widget.initialEntry?.cardRecord;
    _localCacheBustVersion = widget.cacheBustVersion;
    debugPrint('CATDEX_CARD_DETAIL_ROUTE_OPENED id=$_discoveryId');
    debugPrint('CATDEX_CARD_DETAIL_OPENED id=$_discoveryId cardId=$_cardId');
    unawaited(_loadLatestDiscovery());
  }

  @override
  void dispose() {
    _disposed = true;
    _loadRequestToken += 1;
    _longWaitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generationStateListenable = cardGenerationStateProvider.select(
      (states) => states[_discoveryId] ?? CardGenerationSharedState.idle,
    );
    final sharedGenerationState = ref.watch(generationStateListenable);
    ref.listen<CardGenerationSharedState>(
      generationStateListenable,
      (previous, next) {
        if (next.isCompleted &&
            (previous == null ||
                !previous.isCompleted ||
                previous.revision != next.revision)) {
          _localCacheBustVersion = DateTime.now().millisecondsSinceEpoch;
          unawaited(_loadLatestDiscovery(showLoading: false));
        }
      },
    );
    _logSharedGenerationState(sharedGenerationState);

    final discovery = _discovery;
    final display = discovery == null
        ? null
        : const CatDisplayFormatter().fromDiscovery(
            discovery,
            fallbackName:
                widget.initialEntry?.displayName ?? discovery.customName,
          );
    final finalUrl = _resolvedFinalUrl;
    final imageSource = finalUrl == null
        ? null
        : cacheBustedCardImageUrl(
            source: finalUrl,
            version: _localCacheBustVersion,
          );
    final hasGeneratedArtwork = finalUrl != null;
    final generating = sharedGenerationState.isGenerating;
    final awaitingCompletedRefresh =
        sharedGenerationState.isCompleted && !hasGeneratedArtwork;

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, result) => _handleRoutePop(didPop),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF111827),
                        Color(0xFF0B1020),
                        Color(0xFF050816),
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      76,
                      AppSpacing.lg,
                      40,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CardHeroFrame(
                              imageSource: imageSource,
                              entityMissing: _entityMissing,
                              repositoryLoading:
                                  _repositoryLoading ||
                                  awaitingCompletedRefresh,
                              imageLoadFailed: _imageLoadFailed,
                              generating: generating,
                              generatingLabel: sharedGenerationState.label,
                              hasGenerationError:
                                  sharedGenerationState.hasFailed,
                              onImageError: _handleImageLoadError,
                              onImageLoading: _handleImageLoading,
                              onRetryImage: imageSource == null
                                  ? null
                                  : () => _retryImageLoad(imageSource),
                              onGenerate:
                                  _repositoryLoading ||
                                      generating ||
                                      awaitingCompletedRefresh ||
                                      hasGeneratedArtwork ||
                                      _entityMissing ||
                                      widget.onGenerate == null
                                  ? null
                                  : () => _runGeneration(
                                      callback: widget.onGenerate!,
                                      successMessage: 'Carta generata',
                                    ),
                            ),
                            if (!_entityMissing) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _CardMetadataPanel(
                                display: display,
                                cardNumber: _cardNumber,
                                discoveredDate: _discoveredDate(discovery),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _CardActionsPanel(
                                hasImage: hasGeneratedArtwork,
                                generating: generating,
                                onRegenerate:
                                    generating || widget.onRegenerate == null
                                    ? null
                                    : () => _runGeneration(
                                        callback: widget.onRegenerate!,
                                        successMessage: 'Carta aggiornata',
                                      ),
                                onShare: finalUrl == null
                                    ? null
                                    : () => _copyImageReference(finalUrl),
                                onSave: finalUrl == null
                                    ? null
                                    : () => _showImageSaveFeedback(finalUrl),
                              ),
                              CatDexBannerAdWidget(
                                placementLog:
                                    'CATDEX_AD_BANNER_PLACEMENT_CARD_DETAIL',
                                safeForAds: !generating,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.sm,
                top: AppSpacing.sm,
                child: Material(
                  color: AppColors.ink.withValues(alpha: 0.54),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: CatDexLocalizations.of(context).backAction,
                    onPressed: _requestBack,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runGeneration({
    required CardGenerationCallback callback,
    required String successMessage,
  }) async {
    final generationController = ref.read(
      cardGenerationStateProvider.notifier,
    );
    if (!generationController.begin(
      _discoveryId,
      label: _cardGenerationPendingLabel,
    )) {
      debugPrint('CATDEX_CARD_GENERATION_DUPLICATE_BLOCKED');
      return;
    }

    debugPrint('CATDEX_CARD_GENERATION_USER_TAP');
    debugPrint('CATDEX_CARD_UI_SINGLE_TAP_HANDLED');
    debugPrint('CATDEX_CARD_UI_GENERATING_STARTED');
    _startLongWaitMessage();

    String? result;
    var completedSuccessfully = false;
    try {
      result = await callback();
      if (!mounted || _disposed) {
        debugPrint('CATDEX_CARD_DETAIL_ASYNC_IGNORED_AFTER_DISPOSE');
        return;
      }
      if (result != null && isFinalGeneratedCardImageSource(result)) {
        _localCacheBustVersion = DateTime.now().millisecondsSinceEpoch;
        await _loadLatestDiscovery(showLoading: false);
        if (!mounted || _disposed) {
          debugPrint('CATDEX_CARD_DETAIL_ASYNC_IGNORED_AFTER_DISPOSE');
          return;
        }
        completedSuccessfully = hasPersistedGeneratedCard(_discovery);
      }
    } finally {
      _longWaitTimer?.cancel();
      _longWaitTimer = null;
    }

    if (!mounted) {
      return;
    }

    if (result == null || result.trim().isEmpty) {
      if (generationController.forDiscovery(_discoveryId).isGenerating) {
        generationController.fail(_discoveryId);
      }
      debugPrint('CATDEX_CARD_UI_SERVICE_COMPLETED_FAILURE');
      _showSnackBar('Errore generazione carta');
      return;
    }
    if (!isFinalGeneratedCardImageSource(result) || !completedSuccessfully) {
      generationController.fail(_discoveryId);
      debugPrint('CATDEX_CARD_IMAGE_REJECTED_ORIGINAL_PHOTO_PATH');
      debugPrint('CATDEX_CARD_GENERATION_FAILED_KEEP_EXISTING_IMAGE');
      debugPrint('CATDEX_CARD_UI_SERVICE_COMPLETED_FAILURE');
      _showSnackBar('Errore generazione carta');
      return;
    }

    if (generationController.forDiscovery(_discoveryId).isGenerating) {
      generationController.complete(_discoveryId);
    }
    debugPrint('CATDEX_CARD_UI_SERVICE_COMPLETED_SUCCESS');
    _showSnackBar(successMessage);
  }

  String get _discoveryId {
    final explicit = widget.discoveryId.trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    return widget.initialEntry?.discovery?.id ?? '';
  }

  String get _cardId {
    final explicit = widget.cardId?.trim();
    if (explicit?.isNotEmpty == true) return explicit!;
    final entryCardId = widget.initialEntry?.cardRecord?.cardId.trim();
    if (entryCardId?.isNotEmpty == true) return entryCardId!;
    return normalCardId(_discoveryId);
  }

  String? get _resolvedFinalUrl {
    final record = _cardRecord;
    if (record?.isCompleted == true) return record!.finalCardUrl;
    final discovery = _discovery;
    final legacyCard = discovery?.card;
    if (discovery == null || legacyCard == null) return null;
    if (!legacyCard.isEventCard) {
      return _cardId == normalCardId(discovery.id)
          ? canonicalGeneratedCardUrl(discovery)
          : null;
    }
    final eventKey = legacyCard.eventKey;
    final eventEdition = legacyCard.eventEdition;
    final variantId = legacyCard.eventArtworkVariantId;
    if (eventKey == null || eventEdition == null || variantId == null) {
      return null;
    }
    final legacyEventCardId = eventCardId(
      discoveryId: discovery.id,
      eventKey: eventKey,
      eventEdition: eventEdition,
      eventArtworkVariantId: variantId,
    );
    return _cardId == legacyEventCardId
        ? canonicalGeneratedCardUrl(discovery)
        : null;
  }

  int get _collectionNumber {
    if (widget.collectionNumber > 0) {
      return widget.collectionNumber;
    }
    return widget.initialEntry?.collectionNumber ?? 0;
  }

  String get _cardNumber => '#${_collectionNumber.toString().padLeft(4, '0')}';

  Future<void> _loadLatestDiscovery({bool showLoading = true}) async {
    if (!mounted || _disposed) {
      debugPrint('CATDEX_CARD_DETAIL_PROVIDER_REFRESH_SKIPPED_DISPOSED');
      return;
    }
    if (_discoveryId.isEmpty) {
      setState(() {
        _repositoryLoading = false;
        _entityMissing = true;
      });
      debugPrint('CATDEX_CARD_DETAIL_ENTITY_MISSING id=-');
      return;
    }

    final requestToken = ++_loadRequestToken;
    debugPrint('CATDEX_CARD_DETAIL_LOAD_STARTED id=$_discoveryId');
    debugPrint('CATDEX_CARD_DETAIL_REPOSITORY_LOOKUP id=$_discoveryId');
    if (showLoading) {
      setState(() {
        _repositoryLoading = true;
      });
    }

    CatDiscovery? latest;
    CatCardRecord? latestCard;
    Object? loadError;
    final repository = ref.read(discoveryRepositoryProvider);
    try {
      latest = await repository.getDiscoveryById(_discoveryId);
      latestCard = await ref
          .read(catCardRepositoryProvider)
          .getCardById(_cardId);
      if (latest != null && latestCard != null) {
        latest = discoveryWithCardRecordForDisplay(latest, latestCard);
      }
    } on Object catch (error) {
      loadError = error;
      debugPrint(
        'CATDEX_CARD_DETAIL_REPOSITORY_LOOKUP_FAILED '
        'id=$_discoveryId error=$error',
      );
    }

    if (!mounted || _disposed) {
      debugPrint('CATDEX_CARD_DETAIL_ASYNC_IGNORED_AFTER_DISPOSE');
      debugPrint('CATDEX_CARD_DETAIL_PROVIDER_REFRESH_SKIPPED_DISPOSED');
      return;
    }
    if (requestToken != _loadRequestToken) {
      debugPrint('CATDEX_CARD_DETAIL_STALE_LOAD_IGNORED id=$_discoveryId');
      return;
    }
    setState(() {
      _discovery = latest ?? (loadError == null ? null : _discovery);
      _cardRecord = latestCard ?? (loadError == null ? null : _cardRecord);
      _entityMissing =
          latest == null && (loadError == null || _discovery == null);
      _repositoryLoading = false;
      _imageLoadFailed = false;
      _imageLoadingLogged = false;
    });
    if (_entityMissing) {
      debugPrint('CATDEX_CARD_DETAIL_ENTITY_MISSING id=$_discoveryId');
    }
    debugPrint(
      'CATDEX_CARD_DETAIL_LOAD_COMPLETED '
      'id=$_discoveryId found=${latest != null}',
    );
    _logDetailState();
  }

  void _logDetailState() {
    final finalUrl = _resolvedFinalUrl;
    final generationState = ref.read(
      cardGenerationStateProvider.select(
        (states) => states[_discoveryId] ?? CardGenerationSharedState.idle,
      ),
    );
    final generateCtaVisible =
        !_repositoryLoading &&
        !_entityMissing &&
        finalUrl == null &&
        !generationState.isGenerating &&
        !generationState.isCompleted;
    final state = generationState.isGenerating
        ? 'generating'
        : generationState.hasFailed
        ? 'generation_error'
        : _repositoryLoading
        ? 'loading'
        : _entityMissing
        ? 'missing'
        : _imageLoadFailed && finalUrl != null
        ? 'image_error'
        : finalUrl != null
        ? 'generated'
        : 'ungenerated';
    debugPrint('CATDEX_CARD_DETAIL_FINAL_URL ${finalUrl ?? '-'}');
    debugPrint(
      'CATDEX_CARD_DETAIL_GENERATION_STATUS '
      '${finalUrl == null ? 'missing' : 'completed'}',
    );
    debugPrint('CATDEX_CARD_DETAIL_STATE $state');
    debugPrint(
      'CATDEX_CARD_DETAIL_GENERATE_CTA_VISIBLE '
      '$generateCtaVisible',
    );
    if (finalUrl != null) {
      debugPrint('CATDEX_CARD_DETAIL_EXISTING_ARTWORK_USED');
      debugPrint('CATDEX_CARD_DETAIL_NO_REGENERATION_REQUEST');
    }
  }

  void _handleImageLoadError(Object error) {
    if (!mounted || _disposed) {
      debugPrint('CATDEX_CARD_DETAIL_ASYNC_IGNORED_AFTER_DISPOSE');
      return;
    }
    if (_imageLoadFailed) {
      return;
    }
    setState(() {
      _imageLoadFailed = true;
    });
    debugPrint('CATDEX_CARD_DETAIL_IMAGE_ERROR $error');
    debugPrint('CATDEX_CARD_DETAIL_IMAGE_LOAD_ERROR $error');
    _logDetailState();
  }

  void _handleImageLoading() {
    if (!mounted || _disposed || _imageLoadingLogged) {
      return;
    }
    _imageLoadingLogged = true;
    debugPrint('CATDEX_CARD_DETAIL_IMAGE_LOADING id=$_discoveryId');
  }

  void _retryImageLoad(String source) {
    if (!mounted || _disposed) {
      return;
    }
    final provider = isNetworkCardImageUrl(source)
        ? NetworkImage(source)
        : FileImage(File(source));
    imageCache.evict(provider);
    setState(() {
      _imageLoadFailed = false;
      _imageLoadingLogged = false;
      _localCacheBustVersion = DateTime.now().millisecondsSinceEpoch;
    });
    _logDetailState();
  }

  void _startLongWaitMessage() {
    _longWaitTimer?.cancel();
    _longWaitTimer = Timer(_cardGenerationLongWaitThreshold, () {
      if (!mounted ||
          !ref
              .read(cardGenerationStateProvider.notifier)
              .forDiscovery(_discoveryId)
              .isGenerating) {
        return;
      }
      ref
          .read(cardGenerationStateProvider.notifier)
          .updateLabel(_discoveryId, _cardGenerationLongWaitLabel);
      debugPrint('CATDEX_CARD_UI_LONG_WAIT_MESSAGE_SHOWN');
      debugPrint('CATDEX_CARD_UI_PREMATURE_TIMEOUT_BLOCKED');
    });
  }

  void _logSharedGenerationState(CardGenerationSharedState state) {
    if (_lastLoggedSharedPhase == state.phase) {
      return;
    }
    _lastLoggedSharedPhase = state.phase;
    debugPrint(
      'CATDEX_CARD_DETAIL_USING_GLOBAL_GENERATION_STATE '
      '$_discoveryId ${state.phase.name}',
    );
    if (state.isGenerating) {
      debugPrint('CATDEX_CARD_GENERATION_BUTTON_DISABLED $_discoveryId');
    }
  }

  Future<void> _copyImageReference(String source) async {
    await Clipboard.setData(ClipboardData(text: source));
    if (mounted) {
      _showSnackBar('Link carta copiato');
    }
  }

  void _showImageSaveFeedback(String source) {
    final isLocal =
        !(source.startsWith('http://') || source.startsWith('https://'));
    _showSnackBar(
      isLocal
          ? 'Immagine già salvata sul dispositivo'
          : 'Usa Condividi per copiare il link immagine',
    );
  }

  void _showSnackBar(String message) {
    if (!mounted || _disposed) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _requestBack() async {
    if (_backRequested || !mounted || _disposed) {
      return;
    }
    _backRequested = true;
    debugPrint('CATDEX_CARD_DETAIL_BACK_REQUESTED id=$_discoveryId');
    final navigator = Navigator.of(context);
    final didPop = await navigator.maybePop();
    if (!didPop && mounted && !_disposed) {
      _backRequested = false;
    }
  }

  void _handleRoutePop(bool didPop) {
    if (!didPop || _backCompletedLogged) {
      return;
    }
    if (!_backRequested) {
      _backRequested = true;
      debugPrint('CATDEX_CARD_DETAIL_BACK_REQUESTED id=$_discoveryId');
    }
    _backCompletedLogged = true;
    debugPrint('CATDEX_CARD_DETAIL_BACK_COMPLETED id=$_discoveryId');
  }
}

String _discoveredDate(CatDiscovery? discovery) {
  final date = discovery?.discoveredAt;
  if (date == null) {
    return '-';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _CardHeroFrame extends StatelessWidget {
  const _CardHeroFrame({
    required this.imageSource,
    required this.entityMissing,
    required this.repositoryLoading,
    required this.imageLoadFailed,
    required this.generating,
    required this.generatingLabel,
    required this.hasGenerationError,
    required this.onImageError,
    required this.onImageLoading,
    required this.onRetryImage,
    required this.onGenerate,
  });

  final String? imageSource;
  final bool entityMissing;
  final bool repositoryLoading;
  final bool imageLoadFailed;
  final bool generating;
  final String? generatingLabel;
  final bool hasGenerationError;
  final ValueChanged<Object> onImageError;
  final VoidCallback onImageLoading;
  final VoidCallback? onRetryImage;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withValues(alpha: 0.16),
            AppColors.white.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.20),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AspectRatio(
          aspectRatio: 5 / 7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: entityMissing
                ? const _CardUnavailable()
                : generating && imageSource == null
                ? _MissingGeneratedCard(
                    generating: true,
                    generatingLabel: generatingLabel,
                    hasGenerationError: false,
                    onGenerate: null,
                  )
                : repositoryLoading && imageSource == null
                ? const _CardDetailLoading()
                : imageSource == null
                ? _MissingGeneratedCard(
                    generating: generating,
                    generatingLabel: generatingLabel,
                    hasGenerationError: hasGenerationError,
                    onGenerate: onGenerate,
                  )
                : imageLoadFailed
                ? _CardImageError(onRetry: onRetryImage)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      _FinalCardImage(
                        source: imageSource!,
                        onError: onImageError,
                        onLoading: onImageLoading,
                      ),
                      if (generating)
                        _CardGenerationInProgress(
                          stateLabel: generatingLabel,
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FinalCardImage extends StatefulWidget {
  const _FinalCardImage({
    required this.source,
    required this.onError,
    required this.onLoading,
  });

  final String source;
  final ValueChanged<Object> onError;
  final VoidCallback onLoading;

  @override
  State<_FinalCardImage> createState() => _FinalCardImageState();
}

class _FinalCardImageState extends State<_FinalCardImage> {
  bool _loadingReported = false;
  bool _errorScheduled = false;

  @override
  void didUpdateWidget(covariant _FinalCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _loadingReported = false;
      _errorScheduled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    final isNetwork = isNetworkCardImageUrl(source);
    final provider = isNetwork
        ? NetworkImage(source)
        : FileImage(File(source)) as ImageProvider<Object>;
    if (!isNetwork && !File(source).existsSync()) {
      _scheduleError(StateError('Generated card file not found: $source'));
      return const _CardDetailLoading();
    }

    return Image(
      image: provider,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        _reportLoading();
        return const _CardDetailLoading();
      },
      errorBuilder: (context, error, stackTrace) {
        _scheduleError(error);
        return const _CardDetailLoading();
      },
    );
  }

  void _reportLoading() {
    if (_loadingReported) {
      return;
    }
    _loadingReported = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onLoading();
      }
    });
  }

  void _scheduleError(Object error) {
    if (_errorScheduled) {
      return;
    }
    _errorScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onError(error);
      } else {
        debugPrint('CATDEX_CARD_DETAIL_ASYNC_IGNORED_AFTER_DISPOSE');
      }
    });
  }
}

class _CardUnavailable extends StatelessWidget {
  const _CardUnavailable();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF182238),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.style_outlined,
                color: AppColors.white,
                size: 46,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                CatDexLocalizations.of(context).cardNoLongerAvailable,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDetailLoading extends StatelessWidget {
  const _CardDetailLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF111827),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.white),
      ),
    );
  }
}

class _MissingGeneratedCard extends StatelessWidget {
  const _MissingGeneratedCard({
    required this.generating,
    required this.hasGenerationError,
    required this.onGenerate,
    this.generatingLabel,
  });

  final bool generating;
  final String? generatingLabel;
  final bool hasGenerationError;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    if (generating) {
      return _CardGenerationInProgress(
        stateLabel: generatingLabel,
      );
    }

    final l10n = CatDexLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111827),
            Color(0xFF1F2937),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Icon(
                  hasGenerationError
                      ? Icons.error_outline_rounded
                      : Icons.style_rounded,
                  color: AppColors.white,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              hasGenerationError
                  ? l10n.cardGenerationError
                  : l10n.cardNotGenerated,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.createFinalCardHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: Icon(
                hasGenerationError
                    ? Icons.refresh_rounded
                    : Icons.auto_awesome_rounded,
              ),
              label: Text(
                hasGenerationError ? l10n.retryAction : l10n.generateCard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardGenerationInProgress extends StatelessWidget {
  const _CardGenerationInProgress({required this.stateLabel});

  final String? stateLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ink.withValues(alpha: 0.82),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: CardGenerationStatusContent(stateLabel: stateLabel),
        ),
      ),
    );
  }
}

class _CardImageError extends StatelessWidget {
  const _CardImageError({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF182238),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.image_not_supported_rounded,
                color: AppColors.white,
                size: 46,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Impossibile caricare l’immagine',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Ricarica'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMetadataPanel extends StatelessWidget {
  const _CardMetadataPanel({
    required this.display,
    required this.cardNumber,
    required this.discoveredDate,
  });

  final CatDisplayData? display;
  final String cardNumber;
  final String discoveredDate;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              display?.displayName ?? 'Carta CatDex',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (display != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.localizeDisplayValue(display!.displaySpecies),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _MetadataChip(
                  icon: Icons.auto_awesome_rounded,
                  label: l10n.rarityLabel,
                  value: l10n.localizeDisplayValue(
                    display?.displayRarity ?? '-',
                  ),
                ),
                _MetadataChip(
                  icon: Icons.confirmation_number_rounded,
                  label: l10n.cardLabel,
                  value: cardNumber,
                ),
                _MetadataChip(
                  icon: Icons.calendar_month_rounded,
                  label: l10n.discoveryLabel,
                  value: discoveredDate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.warning, size: 17),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.62),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionsPanel extends StatelessWidget {
  const _CardActionsPanel({
    required this.hasImage,
    required this.generating,
    required this.onRegenerate,
    required this.onShare,
    required this.onSave,
  });

  final bool hasImage;
  final bool generating;
  final VoidCallback? onRegenerate;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        if (!generating && hasImage)
          FilledButton.icon(
            onPressed: onRegenerate,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.regenerateCard),
          ),
        OutlinedButton.icon(
          onPressed: hasImage ? onShare : null,
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(l10n.shareAction),
        ),
        OutlinedButton.icon(
          onPressed: hasImage ? onSave : null,
          icon: const Icon(Icons.download_rounded),
          label: Text(l10n.saveImageAction),
        ),
      ],
    );
  }
}

class CollectibleCatCardPage extends CatDexTradingCardPage {
  const CollectibleCatCardPage({
    required super.entry,
    super.key,
  });
}
