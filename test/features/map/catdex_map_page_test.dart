import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/location/application/discovery_location_capture_service.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_privacy_preferences.dart';
import 'package:catdex/features/location/domain/entities/location_service_result.dart';
import 'package:catdex/features/location/domain/repositories/location_privacy_preferences_repository.dart';
import 'package:catdex/features/location/domain/repositories/location_repository.dart';
import 'package:catdex/features/map/application/catdex_map_controller.dart';
import 'package:catdex/features/map/application/map_discovery_image_provider.dart';
import 'package:catdex/features/map/presentation/catdex_map_page.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catdex_map_marker_service_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty state appears with no located discoveries', (
    tester,
  ) async {
    await _pumpMap(tester, discoveries: const []);

    expect(find.text('Ancora nessun gatto sulla mappa'), findsOneWidget);
    expect(find.text('Apri Cattura'), findsOneWidget);
  });

  testWidgets('permission denied still shows saved markers', (tester) async {
    await _pumpMap(
      tester,
      discoveries: [
        mapTestDiscovery(id: 'located', latitude: 45, longitude: 7),
      ],
      locationRepository: _FakeLocationRepository(
        permission: LocationPermissionStatus.denied,
      ),
    );

    expect(find.byKey(const ValueKey('map-marker-located')), findsOneWidget);
  });

  testWidgets('marker tap opens the correct discovery preview', (tester) async {
    await _pumpMap(
      tester,
      discoveries: [
        mapTestDiscovery(id: 'luna', latitude: 45, longitude: 7),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('map-marker-luna')));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('Apri nel CatDex'), findsOneWidget);
  });

  testWidgets('preview displays name species rarity and date', (tester) async {
    await _pumpPreview(
      tester,
      discovery: mapTestDiscovery(
        id: 'preview',
        name: 'Lunetta',
        latitude: 45,
        longitude: 7,
      ),
    );

    expect(find.text('Lunetta'), findsOneWidget);
    expect(find.textContaining('Gatto domestico'), findsOneWidget);
    expect(find.text('Non comune'), findsOneWidget);
    expect(find.textContaining('15/07/2026'), findsOneWidget);
  });

  testWidgets('approximate location is labeled without coordinates', (
    tester,
  ) async {
    await _pumpPreview(
      tester,
      discovery: mapTestDiscovery(
        id: 'approximate',
        latitude: 45.07,
        longitude: 7.69,
        approximate: true,
      ),
    );

    expect(find.text('Posizione approssimativa'), findsOneWidget);
    expect(find.textContaining('45.07'), findsNothing);
    expect(find.textContaining('7.69'), findsNothing);
  });

  testWidgets('open in CatDex uses the stable discovery id', (tester) async {
    String? openedId;
    await _pumpPreview(
      tester,
      discovery: mapTestDiscovery(
        id: 'stable-id',
        latitude: 45,
        longitude: 7,
      ),
      onOpenDiscovery: (id) => openedId = id,
    );

    await tester.tap(find.byKey(const ValueKey('map-open-catdex-detail')));
    await tester.pump();

    expect(openedId, 'stable-id');
  });

  testWidgets('current location is not requested automatically at startup', (
    tester,
  ) async {
    final repository = _FakeLocationRepository(
      permission: LocationPermissionStatus.denied,
    );
    await _pumpMap(
      tester,
      discoveries: [
        mapTestDiscovery(id: 'located', latitude: 45, longitude: 7),
      ],
      locationRepository: repository,
    );

    expect(repository.requestPermissionCount, 0);
    expect(repository.currentLocationCount, 0);
  });

  testWidgets('location permission is explained before being requested', (
    tester,
  ) async {
    final repository = _FakeLocationRepository(
      permission: LocationPermissionStatus.denied,
    );
    await _pumpMap(
      tester,
      discoveries: [
        mapTestDiscovery(id: 'located', latitude: 45, longitude: 7),
      ],
      locationRepository: repository,
    );

    await tester.tap(find.byKey(const ValueKey('map-current-location')));
    await tester.pump();

    expect(find.text('Permesso posizione necessario'), findsOneWidget);
    expect(repository.requestPermissionCount, 0);
  });

  testWidgets('GPS disabled does not break saved map markers', (tester) async {
    await _pumpMap(
      tester,
      discoveries: [
        mapTestDiscovery(id: 'located', latitude: 45, longitude: 7),
      ],
      locationRepository: _FakeLocationRepository(
        serviceEnabled: false,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('map-current-location')));
    await tester.pump();

    expect(find.byKey(const ValueKey('map-marker-located')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small viewport has no layout overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpMap(tester, discoveries: const []);

    expect(tester.takeException(), isNull);
  });

  testWidgets('preview remains readable in dark theme at text scale 1.3', (
    tester,
  ) async {
    await _pumpPreview(
      tester,
      discovery: mapTestDiscovery(
        id: 'dark',
        name: 'Un nome di gatto piuttosto lungo',
        latitude: 45,
        longitude: 7,
      ),
      theme: ThemeData.dark(),
      textScale: 1.3,
    );

    final nameFinder = find.text('Un nome di gatto piuttosto lungo');
    expect(nameFinder, findsOneWidget);
    final color = DefaultTextStyle.of(
      tester.element(nameFinder),
    ).style.color;
    expect(color?.computeLuminance(), greaterThan(0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('location removal immediately removes the marker', (
    tester,
  ) async {
    final session = _TestDiscoverySession([
      mapTestDiscovery(id: 'remove', latitude: 45, longitude: 7),
    ]);
    final container = _mapContainer(
      session: session,
      mapActions: _TestMapActions((id) async {
        session.removeLocation(id);
        return true;
      }),
    );
    addTearDown(container.dispose);
    await _pumpMapWithContainer(tester, container);

    expect(find.byKey(const ValueKey('map-marker-remove')), findsOneWidget);
    await container.read(catDexMapActionsProvider).removeLocation('remove');
    await tester.pump();

    expect(find.byKey(const ValueKey('map-marker-remove')), findsNothing);
  });
}

Future<void> _pumpMap(
  WidgetTester tester, {
  required List<CatDiscovery> discoveries,
  LocationRepository? locationRepository,
}) async {
  final container = _mapContainer(
    session: _TestDiscoverySession(discoveries),
    locationRepository: locationRepository,
  );
  addTearDown(container.dispose);
  await _pumpMapWithContainer(tester, container);
}

Future<void> _pumpMapWithContainer(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _localizedApp(
        home: const CatDexMapPage(tilesEnabled: false),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required CatDiscovery discovery,
  ValueChanged<String>? onOpenDiscovery,
  ThemeData? theme,
  double textScale = 1,
}) async {
  final container = ProviderContainer(
    overrides: [
      localDiscoverySessionProvider.overrideWith(
        () => _TestDiscoverySession([discovery]),
      ),
      mapDiscoveryImageProvider.overrideWith((ref, discovery) async {
        return const CatDexResolvedImage.none(
          source: 'test',
          candidates: [],
          placeholderReason: 'test',
          discoveryDebugJson: {},
        );
      }),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _localizedApp(
        theme: theme,
        textScale: textScale,
        home: Scaffold(
          body: CatDexMapDiscoveryPreview(
            discoveryId: discovery.id,
            onOpenDiscovery: onOpenDiscovery,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProviderContainer _mapContainer({
  required _TestDiscoverySession session,
  LocationRepository? locationRepository,
  CatDexMapActions? mapActions,
}) {
  return ProviderContainer(
    overrides: [
      localDiscoverySessionProvider.overrideWith(() => session),
      catDexMapLoadProvider.overrideWith((ref) async {}),
      discoveryLocationRepositoryProvider.overrideWithValue(
        locationRepository ?? _FakeLocationRepository(),
      ),
      locationPrivacyPreferencesRepositoryProvider.overrideWithValue(
        _MemoryLocationPreferencesRepository(),
      ),
      mapDiscoveryImageProvider.overrideWith((ref, discovery) async {
        return const CatDexResolvedImage.none(
          source: 'test',
          candidates: [],
          placeholderReason: 'test',
          discoveryDebugJson: {},
        );
      }),
      if (mapActions != null)
        catDexMapActionsProvider.overrideWithValue(mapActions),
    ],
  );
}

Widget _localizedApp({
  required Widget home,
  ThemeData? theme,
  double textScale = 1,
}) {
  return MaterialApp(
    locale: const Locale('it'),
    supportedLocales: CatDexLocalizations.supportedLocales,
    localizationsDelegates: CatDexLocalizations.localizationsDelegates,
    theme: theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: home,
  );
}

class _TestDiscoverySession extends LocalDiscoverySessionController {
  _TestDiscoverySession(this.discoveries);

  final List<CatDiscovery> discoveries;

  @override
  List<CatDiscovery> build() => discoveries;

  @override
  Future<void> refreshFromRepository() async {}

  void removeLocation(String discoveryId) {
    state = [
      for (final discovery in state)
        if (discovery.id == discoveryId)
          discovery.copyWithLocation(clearCaptureLocation: true)
        else
          discovery,
    ];
  }
}

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository({
    this.permission = LocationPermissionStatus.granted,
    this.serviceEnabled = true,
  });

  LocationPermissionStatus permission;
  final bool serviceEnabled;
  int requestPermissionCount = 0;
  int currentLocationCount = 0;

  @override
  Future<LocationPermissionStatus> checkPermission() async => permission;

  @override
  Future<bool> checkServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationServiceResult> getCurrentLocation() async {
    currentLocationCount += 1;
    return const LocationServiceSuccess(
      CatDiscoveryLocation(latitude: 45, longitude: 7),
    );
  }

  @override
  Future<LocationServiceResult> getLastKnownLocation() async {
    return const LocationServiceFailure(LocationFailureReason.unavailable);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    requestPermissionCount += 1;
    return permission = LocationPermissionStatus.granted;
  }
}

class _MemoryLocationPreferencesRepository
    implements LocationPrivacyPreferencesRepository {
  LocationPrivacyPreferences value =
      const LocationPrivacyPreferences.defaults();

  @override
  Future<LocationPrivacyPreferences> getPreferences() async => value;

  @override
  Future<void> savePreferences(
    LocationPrivacyPreferences preferences,
  ) async {
    value = preferences;
  }
}

class _TestMapActions implements CatDexMapActions {
  const _TestMapActions(this.remove);

  final Future<bool> Function(String discoveryId) remove;

  @override
  Future<bool> removeLocation(String discoveryId) => remove(discoveryId);
}
