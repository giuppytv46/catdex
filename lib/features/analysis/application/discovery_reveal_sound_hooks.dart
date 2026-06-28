import 'package:flutter_riverpod/flutter_riverpod.dart';

final discoveryRevealSoundHooksProvider = Provider<DiscoveryRevealSoundHooks>((
  _,
) {
  return const NoOpDiscoveryRevealSoundHooks();
});

abstract interface class DiscoveryRevealSoundHooks {
  void playCommonReveal();

  void playRareReveal();

  void playShinyReveal();

  void playLevelUp();
}

class NoOpDiscoveryRevealSoundHooks implements DiscoveryRevealSoundHooks {
  const NoOpDiscoveryRevealSoundHooks();

  @override
  void playCommonReveal() {}

  @override
  void playRareReveal() {}

  @override
  void playShinyReveal() {}

  @override
  void playLevelUp() {}
}
