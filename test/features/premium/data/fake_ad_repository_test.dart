import 'package:catdex/features/premium/data/fake_ad_repository.dart';
import 'package:catdex/features/premium/domain/entities/monetization_placement.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAdRepository', () {
    test(
      'defines future ad placements but keeps all disabled by default',
      () async {
        const repository = FakeAdRepository();

        final placements = await repository.getPlacements();

        expect(
          placements.map((placement) => placement.type),
          containsAll(MonetizationPlacementType.values),
        );
        final allPlacementsDisabled = placements.every((placement) {
          return !placement.enabled;
        });

        expect(allPlacementsDisabled, isTrue);
      },
    );

    test('reports each placement type as disabled', () async {
      const repository = FakeAdRepository();

      for (final type in MonetizationPlacementType.values) {
        expect(await repository.isPlacementEnabled(type), isFalse);
      }
    });
  });
}
