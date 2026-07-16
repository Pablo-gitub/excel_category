class AppRoutes {
  AppRoutes._();

  static const String splashName = 'splash';
  static const String splashPath = '/';

  static const String onboardingName = 'onboarding';
  static const String onboardingPath = '/onboarding';

  static const String homeName = 'home';
  static const String homePath = '/home';

  static const String datasetListName = 'datasetList';
  static const String datasetListPath = '/datasets';

  static const String datasetName = 'dataset';
  static const String datasetPath = '/datasets/:datasetId';

  static const String multiDatasetAnalyticsName = 'multiDatasetAnalytics';
  static const String multiDatasetAnalyticsPath =
      '/datasets/:datasetId/analytics';

  /// Guided multi-sheet join workspace ("Combine sheets").
  static const String sheetJoinsName = 'sheetJoins';
  static const String sheetJoinsPath = '/datasets/:datasetId/joins';

  static const String settingsName = 'settings';
  static const String settingsPath = '/settings';

  static const String datasetIdParam = 'datasetId';
}
