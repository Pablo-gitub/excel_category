import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/update_service.dart';
import 'package:exlser/data/services/github_release_models.dart';
import 'package:exlser/presentation/providers/immersive_mode_provider.dart';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:exlser/presentation/views/settings/settings_update_controller.dart';
import 'package:exlser/presentation/views/settings/settings_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpSettings(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: UncontrolledProviderScope(
          container: container,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const Scaffold(
                body: SettingsView(),
              ),
            ),
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  test('disables desktop updates in web builds', () {
    expect(
      desktopUpdatePlatformFromTarget(
        TargetPlatform.macOS,
        isWeb: true,
      ),
      DesktopUpdatePlatform.unsupported,
    );
    expect(
      desktopUpdatePlatformFromTarget(
        TargetPlatform.windows,
        isWeb: true,
      ),
      DesktopUpdatePlatform.unsupported,
    );
  });

  testWidgets('shows and toggles full immersion only on Android',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    try {
      await _pumpSettings(tester, container: container);

      expect(find.text('Full immersion'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(container.read(immersiveModeProvider), isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(container.read(immersiveModeProvider), isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('hides full immersion outside Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    try {
      await _pumpSettings(tester, container: container);

      expect(find.text('Full immersion'), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Check for updates'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('checks for updates on desktop and reports up to date',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final container = ProviderContainer(
      overrides: [
        updateServiceProvider.overrideWithValue(
          _updateService([
            _release(tagName: 'desktop-v2.0.1'),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    try {
      await _pumpSettings(tester, container: container);

      expect(find.text('Check for updates'), findsOneWidget);

      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();

      expect(
        find.text('You are using the latest desktop version.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('shows update dialog when a newer desktop release exists',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final container = ProviderContainer(
      overrides: [
        updateServiceProvider.overrideWithValue(
          _updateService([
            _release(
              tagName: 'desktop-v2.1.0',
              assets: [
                _asset('exlser-2.1.0-macos.zip'),
              ],
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    try {
      await _pumpSettings(tester, container: container);

      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();

      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Exlser 2.1.0 is available.'), findsWidgets);
      expect(find.text('Download update'), findsWidgets);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

UpdateService _updateService(List<GitHubRelease> releases) {
  return UpdateService(
    releaseClient: _FakeGitHubReleaseClient(releases),
    owner: 'owner',
    repo: 'repo',
    currentVersion: '2.0.1+201',
  );
}

GitHubRelease _release({
  required String tagName,
  List<GitHubReleaseAsset> assets = const [],
}) {
  return GitHubRelease(
    tagName: tagName,
    name: tagName,
    htmlUrl: Uri.parse('https://example.com/releases/$tagName'),
    body: null,
    draft: false,
    prerelease: false,
    assets: assets,
  );
}

GitHubReleaseAsset _asset(String name) {
  return GitHubReleaseAsset(
    name: name,
    browserDownloadUrl: Uri.parse('https://example.com/download.zip'),
    size: 1024,
  );
}

class _FakeGitHubReleaseClient implements GitHubReleaseClient {
  final List<GitHubRelease> releases;

  _FakeGitHubReleaseClient(this.releases);

  @override
  Future<List<GitHubRelease>> fetchReleases({
    required String owner,
    required String repo,
    int perPage = 20,
  }) async {
    return releases;
  }
}
