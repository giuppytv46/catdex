import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/data/shared_preferences_cat_card_repository.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('local explorer keeps cat card persistence local without user UUID', () {
    final container = ProviderContainer(
      overrides: [cloudUserIdProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(catCardRepositoryProvider),
      isA<SharedPreferencesCatCardRepository>(),
    );
  });
}
