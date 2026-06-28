import 'dart:async';
import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/capture/application/capture_controller.dart';
import 'package:catdex/features/capture/application/capture_state.dart';
import 'package:catdex/features/capture/application/photo_upload_controller.dart';
import 'package:catdex/features/capture/application/photo_upload_state.dart';
import 'package:catdex/features/location/application/location_controller.dart';
import 'package:catdex/features/location/application/location_state.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CapturePage extends ConsumerWidget {
  const CapturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CatDexLocalizations.of(context);
    final captureState = ref.watch(captureControllerProvider);
    final uploadState = ref.watch(photoUploadControllerProvider);
    final locationState = ref.watch(locationControllerProvider);
    final controller = ref.read(captureControllerProvider.notifier);
    final uploadController = ref.read(photoUploadControllerProvider.notifier);
    final locationController = ref.read(locationControllerProvider.notifier);
    final uploading = uploadState.status == PhotoUploadStatus.uploading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.captureTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            120,
          ),
          children: [
            _CaptureHero(state: captureState),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.captureHeading,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.captureEmptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (captureState.message case final message?)
              _CaptureMessage(message: message),
            if (uploadState.status == PhotoUploadStatus.failed &&
                uploadState.message != null)
              _CaptureMessage(message: uploadState.message!),
            const SizedBox(height: AppSpacing.md),
            _CaptureActions(
              state: captureState,
              onTakePhoto: () {
                uploadController.reset();
                unawaited(controller.takePhoto());
              },
              onImportFromGallery: () {
                uploadController.reset();
                unawaited(controller.importFromGallery());
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (captureState.photo != null)
              _SelectedImagePreview(
                state: captureState,
                locationState: locationState,
                onDetectLocation: locationController.requestCurrentLocation,
                onRemove: () {
                  controller.removeSelectedPhoto();
                  uploadController.reset();
                  locationController.reset();
                },
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: captureState.canContinue && !uploading
                  ? () => _continueToAnalysis(
                      context: context,
                      uploadController: uploadController,
                      captureState: captureState,
                    )
                  : null,
              child: uploading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.continueAction),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continueToAnalysis({
    required BuildContext context,
    required PhotoUploadController uploadController,
    required CaptureState captureState,
  }) async {
    final photo = captureState.photo;
    if (photo == null) {
      return;
    }

    final uploadResult = await uploadController.prepareForAnalysis(photo);
    if (!context.mounted || uploadResult == null) {
      return;
    }

    unawaited(
      context.pushNamed(
        AppRoute.analysis.name,
        extra: uploadResult.photo,
      ),
    );
  }
}

class _CaptureHero extends StatelessWidget {
  const _CaptureHero({required this.state});

  final CaptureState state;

  @override
  Widget build(BuildContext context) {
    final photo = state.photo;

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: photo == null
              ? const _EmptyCameraPlaceholder()
              : Image.file(File(photo.path), fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _EmptyCameraPlaceholder extends StatelessWidget {
  const _EmptyCameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.center_focus_strong_rounded,
          color: AppColors.white.withValues(alpha: 0.95),
          size: 96,
        ),
      ),
    );
  }
}

class _CaptureActions extends StatelessWidget {
  const _CaptureActions({
    required this.state,
    required this.onTakePhoto,
    required this.onImportFromGallery,
  });

  final CaptureState state;
  final VoidCallback onTakePhoto;
  final VoidCallback onImportFromGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final busy =
        state.status == CaptureStatus.requestingPermission ||
        state.status == CaptureStatus.picking;

    return Column(
      children: [
        FilledButton.icon(
          onPressed: busy ? null : onTakePhoto,
          icon: const Icon(Icons.photo_camera_rounded),
          label: Text(l10n.takePhotoAction),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: busy ? null : onImportFromGallery,
          icon: const Icon(Icons.photo_library_rounded),
          label: Text(l10n.importFromGalleryAction),
        ),
      ],
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({
    required this.state,
    required this.locationState,
    required this.onDetectLocation,
    required this.onRemove,
  });

  final CaptureState state;
  final LocationState locationState;
  final VoidCallback onDetectLocation;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return Column(
      children: [
        Semantics(
          label: l10n.selectedImageLabel,
          image: true,
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.selectedImageLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.removeSelectedImageAction,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _locationBusy ? null : onDetectLocation,
          icon: const Icon(Icons.location_on_rounded),
          label: Text(l10n.detectLocationAction),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LocationSummary(state: locationState),
      ],
    );
  }

  bool get _locationBusy {
    return locationState.status == LocationStatus.requestingPermission ||
        locationState.status == LocationStatus.locating;
  }
}

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({required this.state});

  final LocationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final location = state.location;
    final message = state.message;

    if (state.status == LocationStatus.idle) {
      return const SizedBox.shrink();
    }

    if (state.status == LocationStatus.requestingPermission ||
        state.status == LocationStatus.locating) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.detectLocationAction),
        ],
      );
    }

    final label = switch (state.status) {
      LocationStatus.located when location != null =>
        location.hasPlaceDetails
            ? location.displayLabel
            : l10n.coordinatesOnlyLabel,
      LocationStatus.denied => l10n.locationUnavailableLabel,
      LocationStatus.disabled => message ?? l10n.locationUnavailableLabel,
      LocationStatus.failure => message ?? l10n.locationUnavailableLabel,
      _ => l10n.locationUnavailableLabel,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.place_rounded, color: AppColors.skyBlue),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.detectedLocationLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    label,
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
}

class _CaptureMessage extends StatelessWidget {
  const _CaptureMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
