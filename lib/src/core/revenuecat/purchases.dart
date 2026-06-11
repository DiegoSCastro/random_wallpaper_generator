import 'package:flutter/foundation.dart';

/// Stub RevenueCat wrapper. Replace with `purchases_flutter` in v0.2.
class PurchasesService {
  PurchasesService();

  bool _isPro = false;

  Future<void> init() async {
    if (kDebugMode) debugPrint('PurchasesService: init (stub)');
  }

  bool get isPro => _isPro;

  Future<void> purchasePro() async {
    if (kDebugMode) debugPrint('PurchasesService: purchasePro (stub)');
    _isPro = true;
  }

  Future<void> restore() async {
    if (kDebugMode) debugPrint('PurchasesService: restore (stub)');
  }
}
