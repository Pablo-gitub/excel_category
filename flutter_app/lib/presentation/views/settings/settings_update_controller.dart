import 'package:exlser/application/services/update_service.dart';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SettingsUpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  unsupportedPlatform,
  error,
}

class SettingsUpdateState {
  final SettingsUpdateStatus status;
  final UpdateCheckResult? result;
  final String? errorMessage;

  const SettingsUpdateState({
    required this.status,
    this.result,
    this.errorMessage,
  });

  const SettingsUpdateState.idle() : this(status: SettingsUpdateStatus.idle);

  const SettingsUpdateState.checking()
      : this(status: SettingsUpdateStatus.checking);

  SettingsUpdateState.result(UpdateCheckResult result)
      : this(
          status: result.isPlatformSupported
              ? result.isUpdateAvailable
                  ? SettingsUpdateStatus.updateAvailable
                  : SettingsUpdateStatus.upToDate
              : SettingsUpdateStatus.unsupportedPlatform,
          result: result,
        );

  const SettingsUpdateState.error(String message)
      : this(
          status: SettingsUpdateStatus.error,
          errorMessage: message,
        );

  bool get isChecking => status == SettingsUpdateStatus.checking;
  bool get isUpdateAvailable => status == SettingsUpdateStatus.updateAvailable;
}

final desktopUpdatePlatformProvider = Provider<DesktopUpdatePlatform>((ref) {
  return desktopUpdatePlatformFromTarget(
    defaultTargetPlatform,
    isWeb: kIsWeb,
  );
});

final settingsUpdateControllerProvider = StateNotifierProvider.autoDispose<
    SettingsUpdateController, SettingsUpdateState>((ref) {
  return SettingsUpdateController(
    updateService: ref.watch(updateServiceProvider),
    platform: ref.watch(desktopUpdatePlatformProvider),
  );
});

DesktopUpdatePlatform desktopUpdatePlatformFromTarget(
  TargetPlatform platform, {
  bool isWeb = false,
}) {
  if (isWeb) {
    return DesktopUpdatePlatform.unsupported;
  }

  return switch (platform) {
    TargetPlatform.macOS => DesktopUpdatePlatform.macos,
    TargetPlatform.windows => DesktopUpdatePlatform.windows,
    TargetPlatform.linux => DesktopUpdatePlatform.linux,
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia =>
      DesktopUpdatePlatform.unsupported,
  };
}

class SettingsUpdateController extends StateNotifier<SettingsUpdateState> {
  final UpdateService _updateService;
  final DesktopUpdatePlatform _platform;

  SettingsUpdateController({
    required UpdateService updateService,
    required DesktopUpdatePlatform platform,
  })  : _updateService = updateService,
        _platform = platform,
        super(const SettingsUpdateState.idle());

  Future<void> checkForUpdates() async {
    if (state.isChecking) {
      return;
    }

    state = const SettingsUpdateState.checking();

    try {
      final result = await _updateService.checkForUpdate(platform: _platform);
      state = SettingsUpdateState.result(result);
    } on Object catch (error) {
      state = SettingsUpdateState.error(error.toString());
    }
  }
}
