import 'dart:async';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/update_service.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:anchwatt/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class OptionsViewModel extends ChangeNotifier {
  /* Static variables */

  static const Duration _upToDateDismissDelay = Duration(seconds: 3);

  /* Variables */

  final AnchwattViewModel _parent;

  String? _version;
  OptionsUpdateCheck _checkState = const OptionsUpdateIdle();
  UpdateAvailable? _availableUpdate;
  Timer? _upToDateDismissTimer;
  bool _disposed = false;

  /* Constructor */

  OptionsViewModel(this._parent) {
    _parent.soundModeNotifier.addListener(_onSoundModeChanged);
    _parent.silentModeNotifier.addListener(_onSilentModeChanged);
    _boot();
  }

  /* Getters */

  String? get version => _version;
  SoundMode get soundMode => _parent.soundModeNotifier.value;
  bool get silentModeEnabled => _parent.silentModeNotifier.value;
  OptionsUpdateCheck get checkState => _checkState;
  UpdateAvailable? get availableUpdate => _availableUpdate;

  /* Methods */

  Future<void> _boot() async {
    _version = await _readVersion();

    if (_disposed) {
      return;
    }

    final UpdateStatus parentStatus = _parent.updateStatus;

    if (parentStatus is UpdateAvailable) {
      _availableUpdate = parentStatus;
    }

    notifyListeners();
  }

  Future<String?> _readVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();

      return info.version;
    } on Object catch (error) {
      debugPrint('OptionsViewModel: failed to read package info: $error');

      return null;
    }
  }

  void _onSoundModeChanged() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  void _onSilentModeChanged() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  Future<void> setSoundMode(SoundMode mode) async {
    if (_parent.soundModeNotifier.value == mode) {
      return;
    }

    await _parent.toggleSoundMode();
  }

  Future<void> setSilentMode(bool value) async {
    if (_parent.silentModeNotifier.value == value) {
      return;
    }

    await _parent.toggleSilentMode();
  }

  Future<void> checkForUpdatesNow() async {
    if (_checkState is OptionsUpdateLoading) {
      return;
    }

    _upToDateDismissTimer?.cancel();
    _checkState = const OptionsUpdateLoading();

    notifyListeners();

    final UpdateStatus status = await _parent.forceCheckUpdates();

    if (_disposed) {
      return;
    }

    switch (status) {
      case UpdateUpToDate():
        _availableUpdate = null;
        _checkState = const OptionsUpdateUpToDate();
        notifyListeners();
        _upToDateDismissTimer = Timer(_upToDateDismissDelay, _clearUpToDate);

      case UpdateAvailable():
        _availableUpdate = status;
        _checkState = const OptionsUpdateIdle();
        notifyListeners();

      case UpdateUnknown():
        _checkState = const OptionsUpdateError();
        notifyListeners();
    }
  }

  void _clearUpToDate() {
    if (_disposed) {
      return;
    }

    if (_checkState is! OptionsUpdateUpToDate) {
      return;
    }

    _checkState = const OptionsUpdateIdle();

    notifyListeners();
  }

  Future<void> openGithub() async {
    try {
      await launchUrl(
        Uri.parse(Settings.githubRepoUrl),
        mode: LaunchMode.externalApplication,
      );
    } on Object catch (error) {
      debugPrint('OptionsViewModel: failed to open GitHub URL: $error');
    }
  }

  Future<void> openLatestRelease() => _parent.openLatestRelease();

  @override
  void dispose() {
    _disposed = true;
    _upToDateDismissTimer?.cancel();
    _parent.soundModeNotifier.removeListener(_onSoundModeChanged);
    _parent.silentModeNotifier.removeListener(_onSilentModeChanged);

    super.dispose();
  }
}

sealed class OptionsUpdateCheck {
  const OptionsUpdateCheck();
}

class OptionsUpdateIdle extends OptionsUpdateCheck {
  const OptionsUpdateIdle();
}

class OptionsUpdateLoading extends OptionsUpdateCheck {
  const OptionsUpdateLoading();
}

class OptionsUpdateUpToDate extends OptionsUpdateCheck {
  const OptionsUpdateUpToDate();
}

class OptionsUpdateError extends OptionsUpdateCheck {
  const OptionsUpdateError();
}
