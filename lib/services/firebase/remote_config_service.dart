import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

abstract interface class AppRemoteConfigService {
  Future<void> initialize();
  Future<bool> fetchAndActivate();

  int get maxJournalsDisplayed;
  int get maxKeywordsDisplayed;

  static const String keyMaxJournals = 'max_journals_displayed';
  static const String keyMaxKeywords = 'max_keywords_displayed';
}

class FirebaseRemoteConfigService implements AppRemoteConfigService {
  FirebaseRemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults({
        AppRemoteConfigService.keyMaxJournals: 10,
        AppRemoteConfigService.keyMaxKeywords: 5,
      });

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );

      await fetchAndActivate();
    } catch (_) {
      // Best effort initialization
    }
  }

  @override
  Future<bool> fetchAndActivate() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (_) {
      return false;
    }
  }

  @override
  int get maxJournalsDisplayed => _limitOrDefault(
    _remoteConfig.getInt(AppRemoteConfigService.keyMaxJournals),
    fallback: 10,
  );

  @override
  int get maxKeywordsDisplayed => _limitOrDefault(
    _remoteConfig.getInt(AppRemoteConfigService.keyMaxKeywords),
    fallback: 5,
  );

  static int _limitOrDefault(int value, {required int fallback}) {
    if (value <= 0) return fallback;
    return value;
  }
}

class NoOpRemoteConfigService implements AppRemoteConfigService {
  const NoOpRemoteConfigService({this.maxJournals = 10, this.maxKeywords = 5});

  final int maxJournals;
  final int maxKeywords;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> fetchAndActivate() async => true;

  @override
  int get maxJournalsDisplayed => maxJournals <= 0 ? 10 : maxJournals;

  @override
  int get maxKeywordsDisplayed => maxKeywords <= 0 ? 5 : maxKeywords;
}
