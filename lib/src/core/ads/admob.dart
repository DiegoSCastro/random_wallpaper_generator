import 'package:flutter/foundation.dart';

/// Stub AdMob wrapper. Replace with `google_mobile_ads` package in v0.2.
class AdMobService {
  AdMobService();

  bool _initialized = false;
  bool _killSwitch = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (kDebugMode) debugPrint('AdMobService: init (stub)');
  }

  void showBanner() {
    if (_killSwitch) return;
    if (kDebugMode) debugPrint('AdMobService: showBanner (stub)');
  }

  void showInterstitial() {
    if (_killSwitch) return;
    if (kDebugMode) debugPrint('AdMobService: showInterstitial (stub)');
  }

  /// Remote kill switch. Wire to Firebase Remote Config in v0.2.
  void setKillSwitch(bool kill) {
    _killSwitch = kill;
  }
}
