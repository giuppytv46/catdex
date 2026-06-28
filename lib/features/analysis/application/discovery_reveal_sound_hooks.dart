import 'package:flutter_riverpod/flutter_riverpod.dart';

final discoveryRevealSoundHooksProvider = Provider<DiscoveryRevealSoundHooks>((
  _,
) {
  return const NoOpDiscoveryRevealSoundHooks();
});

abstract interface class DiscoveryRevealSoundHooks {
  void playReveal();

  void playRewards();
}

class NoOpDiscoveryRevealSoundHooks implements DiscoveryRevealSoundHooks {
  const NoOpDiscoveryRevealSoundHooks();

  @override
  void playReveal() {}

  @override
  void playRewards() {}
}
