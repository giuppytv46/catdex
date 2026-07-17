import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/events/application/event_ui_state.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeActiveEventSection extends ConsumerStatefulWidget {
  const HomeActiveEventSection({required this.onOpen, super.key});

  final ValueChanged<String> onOpen;

  @override
  ConsumerState<HomeActiveEventSection> createState() =>
      _HomeActiveEventSectionState();
}

class _HomeActiveEventSectionState
    extends ConsumerState<HomeActiveEventSection> {
  bool? _lastVisible;

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(activeEventUiStateProvider);
    return eventState.when(
      data: (state) {
        _logVisibility(state != null);
        if (state == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: HomeEventBanner(
            state: state,
            onOpen: () => widget.onOpen(state.event.id),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) {
        _logVisibility(false);
        return const SizedBox.shrink();
      },
    );
  }

  void _logVisibility(bool visible) {
    if (_lastVisible == visible) return;
    _lastVisible = visible;
    debugPrint(
      visible
          ? 'CATDEX_EVENT_UI_HOME_BANNER_VISIBLE'
          : 'CATDEX_EVENT_UI_HOME_BANNER_HIDDEN',
    );
  }
}

class HomeEventBanner extends StatelessWidget {
  const HomeEventBanner({
    required this.state,
    required this.onOpen,
    super.key,
  });

  final EventUiState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final theme = Theme.of(context);
    final days = _remainingDays(state.event.endsAt);
    final status = state.isPremium
        ? l10n.eventPremiumBadge
        : l10n.eventFreeBadge;

    return Semantics(
      container: true,
      label:
          '${l10n.eventHalloweenTitle}. '
          '${l10n.eventRemaining(state.remainingGenerations)}.',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('home_event_banner'),
          borderRadius: BorderRadius.circular(22),
          onTap: onOpen,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E145F),
                  Color(0xFF6D28D9),
                  Color(0xFFB45309),
                ],
              ),
              border: Border.all(color: const Color(0xFFF6C453), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6D28D9).withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HalloweenMark(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              l10n.eventHalloweenTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            _BannerBadge(label: status),
                            if (state.debugMode)
                              _BannerBadge(
                                key: const Key('home_event_debug_badge'),
                                label: l10n.eventTestBadge,
                                accent: const Color(0xFF7FDBFF),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.eventHalloweenDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFF3E8FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _BannerMeta(
                              icon: Icons.schedule_rounded,
                              label: l10n.eventDaysRemaining(days),
                            ),
                            _BannerMeta(
                              icon: Icons.auto_awesome_rounded,
                              label: l10n.eventRemaining(
                                state.remainingGenerations,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            key: const Key('home_event_open_button'),
                            onPressed: onOpen,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF6C453),
                              foregroundColor: const Color(0xFF28123F),
                              minimumSize: const Size(48, 48),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(l10n.eventDiscoverAction),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HalloweenMark extends StatelessWidget {
  const _HalloweenMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.nightlight_round,
        color: Color(0xFFEA580C),
        size: 30,
      ),
    );
  }
}

class _BannerBadge extends StatelessWidget {
  const _BannerBadge({required this.label, this.accent, super.key});

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? const Color(0xFFF6C453);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BannerMeta extends StatelessWidget {
  const _BannerMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFFFDE68A)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

int _remainingDays(DateTime endsAt) {
  final difference = endsAt.difference(DateTime.now().toUtc());
  if (difference.isNegative) return 0;
  return (difference.inHours / 24).ceil();
}
