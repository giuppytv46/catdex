enum AppRoute {
  splash('/splash'),
  onboarding('/onboarding'),
  login('/login'),
  home('/home'),
  catDex('/catdex'),
  capture('/capture'),
  analysis('/analysis'),
  friends('/friends'),
  profile('/profile'),
  settings('/settings'),
  offline('/offline'),
  globalError('/error'),
  unknown('/unknown');

  const AppRoute(this.path);

  final String path;
}
