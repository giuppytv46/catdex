class ActiveCatDexSession {
  const ActiveCatDexSession.guest({required String playerId})
    : this._(playerId: playerId, cloudSyncEnabled: false);

  const ActiveCatDexSession.cloud({required String playerId})
    : this._(playerId: playerId, cloudSyncEnabled: true);

  const ActiveCatDexSession._({
    required this.playerId,
    required this.cloudSyncEnabled,
  });

  final String playerId;
  final bool cloudSyncEnabled;
}
