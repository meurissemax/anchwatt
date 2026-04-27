import 'dart:async';
import 'dart:convert';

import 'package:anchwatt/main/storages/update_storage.dart';
import 'package:anchwatt/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

sealed class UpdateStatus {
  const UpdateStatus();
}

class UpdateUpToDate extends UpdateStatus {
  const UpdateUpToDate();
}

class UpdateAvailable extends UpdateStatus {
  final String latestVersion;
  final String releaseUrl;

  const UpdateAvailable({
    required this.latestVersion,
    required this.releaseUrl,
  });
}

class UpdateUnknown extends UpdateStatus {
  const UpdateUnknown();
}

class _SemanticVersion {
  final int major;
  final int minor;
  final int patch;

  const _SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
  });

  static _SemanticVersion? parse(String raw) {
    String value = raw.trim();

    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith('v') || value.startsWith('V')) {
      value = value.substring(1);
    }

    final List<String> parts = value.split('.');

    if (parts.length != 3) {
      return null;
    }

    final int? major = int.tryParse(parts[0]);
    final int? minor = int.tryParse(parts[1]);
    final int? patch = int.tryParse(parts[2]);

    if (major == null || minor == null || patch == null) {
      return null;
    }

    if (major < 0 || minor < 0 || patch < 0) {
      return null;
    }

    return _SemanticVersion(major: major, minor: minor, patch: patch);
  }

  bool isOlderThan(_SemanticVersion other) {
    if (major != other.major) {
      return major < other.major;
    }

    if (minor != other.minor) {
      return minor < other.minor;
    }

    return patch < other.patch;
  }
}

class UpdateService {
  /* Static variables */

  static const Duration _timeout = Duration(seconds: 5);
  static const Duration _cooldown = Duration(hours: 2);

  /* Variables */

  final UpdateStorage _storage = UpdateStorage();

  /* Methods */

  Future<UpdateStatus> check() async {
    await _storage.init();

    final _SemanticVersion? localVersion = await _readLocalVersion();
    if (localVersion == null) {
      return const UpdateUnknown();
    }

    final ({int? lastCheckAt, String? latestVersionSeen, String? latestReleaseUrl}) cache = _storage.read();

    final int now = DateTime.now().millisecondsSinceEpoch;
    final int? lastCheckAt = cache.lastCheckAt;
    final bool cooldownActive = lastCheckAt != null && (now - lastCheckAt) < _cooldown.inMilliseconds;

    if (cooldownActive) {
      return _statusFromCache(localVersion, cache);
    }

    return _fetchAndStore(localVersion, now);
  }

  Future<_SemanticVersion?> _readLocalVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();

      return _SemanticVersion.parse(info.version);
    } on Object catch (error) {
      debugPrint('UpdateService: failed to read local version: $error');

      return null;
    }
  }

  UpdateStatus _statusFromCache(
    _SemanticVersion localVersion,
    ({int? lastCheckAt, String? latestVersionSeen, String? latestReleaseUrl}) cache,
  ) {
    final String? seen = cache.latestVersionSeen;
    final String? url = cache.latestReleaseUrl;
    if (seen == null || url == null) {
      return const UpdateUnknown();
    }

    final _SemanticVersion? remote = _SemanticVersion.parse(seen);
    if (remote == null) {
      return const UpdateUnknown();
    }

    if (localVersion.isOlderThan(remote)) {
      return UpdateAvailable(latestVersion: seen, releaseUrl: url);
    }

    return const UpdateUpToDate();
  }

  Future<UpdateStatus> _fetchAndStore(_SemanticVersion localVersion, int now) async {
    final http.Response response;
    try {
      response = await http
          .get(
            Uri.parse(Settings.latestReleaseEndpoint),
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'anchwatt-app',
            },
          )
          .timeout(_timeout);
    } on Object catch (error) {
      debugPrint('UpdateService: network error: $error');

      return const UpdateUnknown();
    }

    if (response.statusCode == 404) {
      try {
        await _storage.writeTimestamp(lastCheckAt: now);
      } on Object catch (error) {
        debugPrint('UpdateService: failed to write timestamp: $error');
      }

      return const UpdateUnknown();
    }

    if (response.statusCode != 200) {
      debugPrint('UpdateService: unexpected status ${response.statusCode}');

      return const UpdateUnknown();
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on Object catch (error) {
      debugPrint('UpdateService: invalid JSON: $error');

      return const UpdateUnknown();
    }

    final Object? tagName = json['tag_name'];
    final Object? htmlUrl = json['html_url'];
    if (tagName is! String || htmlUrl is! String) {
      debugPrint('UpdateService: missing tag_name or html_url');

      return const UpdateUnknown();
    }

    final _SemanticVersion? remote = _SemanticVersion.parse(tagName);
    if (remote == null) {
      debugPrint('UpdateService: unable to parse tag_name "$tagName"');

      return const UpdateUnknown();
    }

    final String normalizedVersion = '${remote.major}.${remote.minor}.${remote.patch}';

    try {
      await _storage.write(
        lastCheckAt: now,
        latestVersionSeen: normalizedVersion,
        latestReleaseUrl: htmlUrl,
      );
    } on Object catch (error) {
      debugPrint('UpdateService: failed to write cache: $error');
    }

    if (localVersion.isOlderThan(remote)) {
      return UpdateAvailable(latestVersion: normalizedVersion, releaseUrl: htmlUrl);
    }

    return const UpdateUpToDate();
  }
}
