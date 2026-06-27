import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/capture/application/capture_controller.dart';
import 'package:catdex/features/capture/application/capture_state.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CapturePage extends ConsumerWidget {
  const CapturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CatDexLocalizations.of(context);
    final captureState = ref.watch(captureControllerProvider);
    final controller = ref.read(captureControllerProvider.notifier);

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
            const SizedBox(height: AppSpacing.md),
            _CaptureActions(
              state: captureState,
              onTakePhoto: controller.takePhoto,
              onImportFromGallery: controller.importFromGallery,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (captureState.photo != null)
              _SelectedImagePreview(
                state: captureState,
                onRemove: controller.removeSelectedPhoto,
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: captureState.canContinue ? () {} : null,
              child: Text(l10n.continueAction),
            ),
          ],
        ),
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
    required this.onRemove,
  });

  final CaptureState state;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return Semantics(
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
