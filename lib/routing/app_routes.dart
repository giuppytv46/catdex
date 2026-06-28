enum AppRoute {
  splash('/splash'),
  onboarding('/onboarding'),
  login('/login'),
  home('/home'),
  catDex('/catdex'),
  capture('/capture'),
  analysis('/analysis'),
  discoveryReveal('/discovery-reveal'),
  friends('/friends'),
  profile('/profile'),
  settings('/settings'),
  premium('/premium'),
  offline('/offline'),
  globalError('/error'),
  unknown('/unknown');

  const AppRoute(this.path);

  final String path;
}
