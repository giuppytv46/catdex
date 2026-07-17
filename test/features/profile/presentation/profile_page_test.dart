import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/profile/presentation/profile_page.dart';
import 'package:catdex/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Profile page builds', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: CatDexLocalizations.localizationsDelegates,
          supportedLocales: CatDexLocalizations.supportedLocales,
          home: const ProfilePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(ProfilePage), findsOneWidget);
  });
}
