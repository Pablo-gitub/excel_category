import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/layout/app_shell.dart';
import '../views/dataset/dataset_view.dart';
import '../views/dataset_list/datasets_list_view.dart';
import '../views/home/home_view.dart';
import '../views/multi_dataset_analytics/multi_dataset_analytics_view.dart';
import '../views/sheet_joins/sheet_joins_view.dart';
import '../views/onboarding/onboarding_view.dart';
import '../views/settings/settings_view.dart';
import '../views/splash/splash_view.dart';
import 'router_notifier.dart';
import 'routes.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create(RouterNotifier routerNotifier) {
    return GoRouter(
      initialLocation: AppRoutes.splashPath,
      refreshListenable: routerNotifier,
      redirect: (BuildContext context, GoRouterState state) {
        final String location = state.matchedLocation;

        final bool isOnSplash = location == AppRoutes.splashPath;
        final bool isOnOnboarding = location == AppRoutes.onboardingPath;

        if (!routerNotifier.isSplashCompleted) {
          return isOnSplash ? null : AppRoutes.splashPath;
        }

        if (!routerNotifier.isOnboardingCompleted) {
          return isOnOnboarding ? null : AppRoutes.onboardingPath;
        }

        if (isOnSplash || isOnOnboarding) {
          return AppRoutes.homePath;
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          name: AppRoutes.splashName,
          path: AppRoutes.splashPath,
          builder: (BuildContext context, GoRouterState state) {
            return const SplashView();
          },
        ),
        GoRoute(
          name: AppRoutes.onboardingName,
          path: AppRoutes.onboardingPath,
          builder: (BuildContext context, GoRouterState state) {
            return const OnboardingView();
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(
              title: _shellTitle(context, state),
              child: child,
            );
          },
          routes: [
            GoRoute(
              name: AppRoutes.homeName,
              path: AppRoutes.homePath,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return NoTransitionPage(
                  key: state.pageKey,
                  child: const HomeView(),
                );
              },
            ),
            GoRoute(
              name: AppRoutes.datasetListName,
              path: AppRoutes.datasetListPath,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return NoTransitionPage(
                  key: state.pageKey,
                  child: const DatasetsListView(),
                );
              },
            ),
            GoRoute(
              name: AppRoutes.datasetName,
              path: AppRoutes.datasetPath,
              pageBuilder: (BuildContext context, GoRouterState state) {
                final int datasetId = _getDatasetId(state);
                return NoTransitionPage(
                  key: state.pageKey,
                  child: DatasetView(
                    key: ValueKey('dataset_$datasetId'),
                    datasetId: datasetId,
                  ),
                );
              },
            ),
            GoRoute(
              name: AppRoutes.multiDatasetAnalyticsName,
              path: AppRoutes.multiDatasetAnalyticsPath,
              pageBuilder: (BuildContext context, GoRouterState state) {
                final int datasetId = _getDatasetId(state);
                return NoTransitionPage(
                  key: state.pageKey,
                  child: MultiDatasetAnalyticsView(datasetId: datasetId),
                );
              },
            ),
            GoRoute(
              name: AppRoutes.sheetJoinsName,
              path: AppRoutes.sheetJoinsPath,
              pageBuilder: (BuildContext context, GoRouterState state) {
                final int datasetId = _getDatasetId(state);
                return NoTransitionPage(
                  key: state.pageKey,
                  child: SheetJoinsView(datasetId: datasetId),
                );
              },
            ),
            GoRoute(
              name: AppRoutes.settingsName,
              path: AppRoutes.settingsPath,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return NoTransitionPage(
                  key: state.pageKey,
                  child: const SettingsView(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

int _getDatasetId(GoRouterState state) {
  final String datasetIdParam = state.pathParameters[AppRoutes.datasetIdParam]!;
  return int.parse(datasetIdParam);
}

String _shellTitle(BuildContext context, GoRouterState state) {
  final location = state.matchedLocation;
  if (location == AppRoutes.homePath) return AppStrings.appName.tr();
  if (location == AppRoutes.datasetListPath) return AppStrings.works.tr();
  if (location == AppRoutes.settingsPath) return AppStrings.settings.tr();
  if (location.startsWith('/datasets/')) {
    if (location.endsWith('/analytics')) {
      return AppStrings.datasetWorkspaceAnalyticsTitle.tr();
    }
    if (location.endsWith('/joins')) {
      return AppStrings.datasetJoinsTitle.tr();
    }
    return AppStrings.datasetWorkspaceTitle.tr();
  }
  return AppStrings.appName.tr();
}
