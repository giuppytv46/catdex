import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CatDexAppShell extends StatelessWidget {
  const CatDexAppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _CatDexBottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _CatDexBottomNavigationBar extends StatelessWidget {
  const _CatDexBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final labels = [
      l10n.homeTitle,
      l10n.catDexTitle,
      l10n.captureTitle,
      l10n.friendsTitle,
      l10n.profileTitle,
    ];
    const icons = [
      Icons.home_rounded,
      Icons.style_rounded,
      Icons.center_focus_strong_rounded,
      Icons.groups_rounded,
      Icons.person_rounded,
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: List.generate(labels.length, (index) {
              final selected = currentIndex == index;
              final isCapture = index == 2;

              return Expanded(
                child: _CatDexNavigationItem(
                  icon: icons[index],
                  label: labels[index],
                  selected: selected,
                  emphasized: isCapture,
                  routePath: _pathForIndex(index),
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _pathForIndex(int index) {
    return switch (index) {
      0 => AppRoute.home.path,
      1 => AppRoute.catDex.path,
      2 => AppRoute.capture.path,
      3 => AppRoute.friends.path,
      _ => AppRoute.profile.path,
    };
  }
}

class _CatDexNavigationItem extends StatelessWidget {
  const _CatDexNavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.emphasized,
    required this.routePath,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool emphasized;
  final String routePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected || emphasized
        ? AppColors.white
        : colorScheme.onSurface;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(emphasized ? 28 : 24),
          onTap: onTap,
          child: AnimatedContainer(
            key: ValueKey(routePath),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: emphasized ? 64 : 56,
            margin: EdgeInsets.only(bottom: emphasized ? AppSpacing.sm : 0),
            decoration: BoxDecoration(
              gradient: selected || emphasized
                  ? const LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.primaryPurple],
                    )
                  : null,
              color: selected || emphasized ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(emphasized ? 28 : 24),
              boxShadow: emphasized
                  ? [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: emphasized ? 30 : 24),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
