import 'package:catdex/shared/celebrations/catdex_celebration_overlay.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('achievement celebration is capped at 16 particles', () {
    final theme = CatDexCelebrationTheme.forPalette(
      CatDexCelebrationPalette.legendary,
    ).boundedForType(CatDexCelebrationType.achievementUnlocked);
    expect(theme.particleCount, 16);
  });

  test('Reduce Motion keeps achievement celebration lightweight', () {
    final theme = CatDexCelebrationTheme.forPalette(
      CatDexCelebrationPalette.legendary,
      reduceMotion: true,
    ).boundedForType(CatDexCelebrationType.achievementUnlocked);
    expect(theme.particleCount, lessThanOrEqualTo(8));
    expect(theme.fireworkCount, 0);
    expect(theme.shakeAmplitude, 0);
  });

  testWidgets('achievement badge visual and copy are shown', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            CatDexCelebrationOverlay(
              request: CatDexCelebrationRequest(
                type: CatDexCelebrationType.achievementUnlocked,
                theme: CatDexCelebrationTheme.forPalette(
                  CatDexCelebrationPalette.common,
                  reduceMotion: true,
                ),
                title: 'TRAGUARDO SBLOCCATO',
                subtitle: 'Prima scoperta\n+50 XP',
                badgeIcon: Icons.pets_rounded,
                reduceMotion: true,
              ),
              onCompleted: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('catdex_celebration_badge_icon')),
      findsOneWidget,
    );
    expect(find.text('TRAGUARDO SBLOCCATO'), findsOneWidget);
    expect(find.textContaining('+50 XP'), findsOneWidget);
  });
}
