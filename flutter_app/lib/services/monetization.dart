import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// "Buy me cups of tea" support purchases (RemoveADS branch model).
///
/// Ads are gone entirely; monetization is now four voluntary non-consumable
/// donation products. The legacy `remove_ads` purchase is grandfathered:
/// owning it makes [isOwned] report `support_3` as owned (the "3 cups" tier
/// shows the thank-you star and its buy button is disabled), but `remove_ads`
/// itself is never offered for sale again.
///
/// Donation billing is active on the Android free build. Apple platforms
/// activate billing too, but ONLY for the separate one-time "Pro" unlock and
/// ONLY once [kApplePurchasesEnabled] is flipped on (which requires the App
/// Store Connect product to exist first) - the donation tiers are never sold
/// off Android. Everywhere billing is inactive (web, or Apple before go-live)
/// the service is inert: [init]/[buy]/[buyPro] are no-ops, [isOwned]/
/// [hasAnySupport]/[isProUnlocked] are always false, and no plugin code is
/// ever touched, so it is safe to call on every platform. (The original branch
/// crashed on the pro flavor because `onResume` hit the uninitialized billing
/// client; this gating keeps that deliberately fixed.)
///
/// ### UI hooks
/// - Listen to the [ChangeNotifier] for ownership changes (stars, disabled
///   buy buttons, the tea-button red badge via [hasAnySupport]).
/// - Listen to [lastUserMessage] for transient user-facing billing messages:
///   it transitions to `null` and then to the message text on every event
///   (so an identical message re-fires listeners); show the non-null value
///   as a SnackBar. Currently the only message is
///   "Purchase is pending. Please wait", emitted on purchase failures other
///   than user-cancel - same (misleading but verbatim) copy the original
///   Snackbar used for any non-OK/non-USER_CANCELED billing result.
class Monetization extends ChangeNotifier {
  Monetization._();

  static final Monetization _instance = Monetization._();

  /// Process-wide singleton.
  static Monetization get instance => _instance;

  /// The four purchasable donation tiers, verbatim from the branch skuList
  /// (support_15/support_29 were removed on the branch - do not add them).
  static const List<String> supportSkus = [
    'support_1',
    'support_3',
    'support_5',
    'support_9',
  ];

  /// Legacy non-consumable from the ads era. Still queried/restored so prior
  /// buyers keep a thank-you star (mapped onto support_3), never sold.
  static const String _legacySku = 'remove_ads';

  /// Everything we query/restore: the four donation tiers, the legacy product,
  /// and the Apple-only Pro unlock ([kProSku]). The Pro product is harmless to
  /// include in the query everywhere - the store simply omits it where it is
  /// not configured - but it only ever becomes purchasable when [isProGated].
  static const Set<String> _allSkus = {...supportSkus, _legacySku, kProSku};

  /// Local persistence of owned products. The Android branch kept entitlements
  /// purely in Play's purchase cache (re-queried every resume), which
  /// momentarily showed supporters as non-supporters while offline or before
  /// billing connected. Fix: persist grants locally and only ever remove one via
  /// [_reconcileOwned] - which drops a SKU ONLY after a SUCCESSFUL restore where
  /// Play reports it as no longer owned (a refund/revoke), never on an offline /
  /// failed query. So a refunded tier becomes purchasable again, while a real
  /// supporter never flickers to non-supporter on a transient outage. (Replaces
  /// the ads-era 'ads_removed' bool.)
  static const String _ownedSkusPrefKey = 'owned_support_skus';

  /// Verbatim Snackbar copy from the original `onPurchasesUpdated`. Shown on
  /// real billing FAILURES (stream error, buy() exception, error-status event).
  static const String _pendingMessage = 'Purchase is pending. Please wait';

  /// Distinct from [_pendingMessage]: shown when a buy is tapped before the
  /// product catalog has loaded (slow/offline first query). Nothing is pending
  /// or failing - the price just is not in yet - so the old "pending" copy was
  /// misleading here.
  static const String _catalogLoadingMessage =
      'Prices are still loading. Please try again in a moment.';

  /// Billing runs on Android (always, for the free-build donations) and on
  /// Apple platforms ONLY once [kApplePurchasesEnabled] is flipped on (which
  /// requires the App Store Connect `pro_unlock` product to exist first). Web
  /// has no IAP. While Apple billing is disabled, Apple builds behave exactly
  /// like web here: inert, no plugin calls, nothing gated.
  static bool get _isActivePlatform {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) return true;
    return isApplePlatform && kApplePurchasesEnabled;
  }

  /// Whether DONATION purchases can happen on this platform. The "buy N cups"
  /// support UI (and the tea-button attention badge) must hide when this is
  /// false. Donations are an Android-only product, so this stays Android-only
  /// even though the billing client is now also active on gated Apple builds
  /// (where it sells the Pro unlock, NOT donations) - keeping its meaning, and
  /// the support screen's behavior, byte-identical to before. (Pro purchase UI
  /// is gated on [canBuyPro], a separate getter.)
  bool get isBillingAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Test-only override of [isProGated]. Production always leaves this `null`
  /// so gating is driven solely by the platform + [kApplePurchasesEnabled]
  /// const. Tests need BOTH gating states regardless of that compile-time
  /// const, so this seam lets them force gating on (Apple-go-live simulation)
  /// or off without recompiling. See [debugSetProGated].
  bool? _debugProGatedOverride;

  /// Whether the Pro gating is in effect: true ONLY on Apple platforms with
  /// [kApplePurchasesEnabled] on. Android, web, and Apple-before-go-live all
  /// report false, so nothing is ever gated there (and no broken locks ship).
  ///
  /// A test may override the result via [debugSetProGated]; production never
  /// touches that seam, so this stays `isApplePlatform && kApplePurchasesEnabled`
  /// in every shipped build.
  bool get isProGated =>
      _debugProGatedOverride ?? (isApplePlatform && kApplePurchasesEnabled);

  /// Whether the Pro one-time unlock ([kProSku]) is owned (persisted in the
  /// existing owned-SKUs cache and restored). Grant-only, like every other
  /// entitlement: once owned, never revoked.
  bool get isProUnlocked => _owned.contains(kProSku);

  /// The single getter UI uses to decide whether premium features are
  /// available. ALWAYS true where gating is off (Android/web/Apple-before-
  /// go-live); on a gated Apple build it tracks Pro ownership.
  bool get hasPro => !isProGated || isProUnlocked;

  /// Whether the Pro unlock can actually be purchased right now: gating is on
  /// AND a purchasable Pro product has loaded from the store.
  bool get canBuyPro => isProGated && _products.containsKey(kProSku);

  /// Localized price string for the Pro unlock from its [ProductDetails], or
  /// null when the product has not loaded (or gating is off).
  String? get proPrice => isProGated ? _products[kProSku]?.price : null;

  bool _initialized = false;
  bool _storeAvailable = false;
  final Set<String> _owned = <String>{};
  final Map<String, ProductDetails> _products = <String, ProductDetails>{};
  SharedPreferences? _prefs;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Future<void>? _pendingStoreRefresh;
  /// Non-null only during a [_refreshStore] restore: collects the SKUs Play
  /// reports as currently owned (via the purchase stream) so [_reconcileOwned]
  /// can drop anything refunded. Null outside a restore so individual purchases
  /// don't trigger reconciliation.
  Set<String>? _restoreCollector;
  final ValueNotifier<String?> _lastUserMessage = ValueNotifier<String?>(null);

  /// Transient user-facing billing message hook (see class docs). The UI
  /// should show the value as a SnackBar whenever it becomes non-null.
  ValueListenable<String?> get lastUserMessage => _lastUserMessage;

  /// Whether the user owns [sku]. Legacy `remove_ads` ownership counts as
  /// owning `support_3` (the branch's grandfathering: same star, same
  /// disabled buy button - and it prevents a double charge for that row).
  bool isOwned(String sku) =>
      _owned.contains(sku) ||
      (sku == 'support_3' && _owned.contains(_legacySku));

  /// Whether ANY product (any tier or the legacy remove_ads) is owned.
  /// Drives the tea button: red attention badge while this is false.
  bool get hasAnySupport => _owned.isNotEmpty;

  /// Loads the persisted grants and wires up billing. Only the local
  /// SharedPreferences read is awaited (it must precede the first frame so
  /// supporters never see the red badge flash); the Play Billing round-trips
  /// (availability check, product query, purchase restore) continue in the
  /// background so cold start is never blocked on store network I/O.
  ///
  /// Safe to call multiple times; every call re-kicks the store refresh -
  /// call it (or [refresh]) on app resume to mirror the original
  /// checkPurchases()-on-every-onResume entitlement refresh.
  Future<void> init() async {
    if (!_isActivePlatform) return;
    if (!_initialized) {
      _initialized = true;
      try {
        _prefs = await SharedPreferences.getInstance();
        final persisted = _prefs?.getStringList(_ownedSkusPrefKey);
        if (persisted != null) {
          _owned.addAll(persisted.where(_allSkus.contains));
        }
      } catch (e) {
        debugPrint('Monetization: failed to read preferences: $e');
      }
      _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
        _onPurchasesUpdated,
        onError: (Object error) {
          debugPrint('Monetization: purchase stream error: $error');
          _postUserMessage(_pendingMessage);
        },
      );
      notifyListeners();
    }
    unawaited(refresh());
  }

  /// Refreshes store availability, the product catalog, and the entitlements
  /// (via restored purchases). Concurrent calls share one in-flight refresh.
  /// Never throws.
  Future<void> refresh() {
    if (!_isActivePlatform || !_initialized) return Future<void>.value();
    return _pendingStoreRefresh ??= _refreshStore().whenComplete(
      () => _pendingStoreRefresh = null,
    );
  }

  /// "Restore Purchases" action for the paywall. Identical to [refresh]:
  /// re-queries the store and re-applies restored purchases (donations AND
  /// Pro), granting any owned-but-not-yet-locally-cached entitlement. Named
  /// separately so the store-mandated restore button reads clearly at the
  /// call site. Never throws; no-op on inert platforms.
  Future<void> restore() => refresh();

  Future<void> _refreshStore() async {
    final iap = InAppPurchase.instance;
    try {
      _storeAvailable = await iap.isAvailable();
      if (_storeAvailable) {
        // Re-query while any required id is still missing, NOT merely while the
        // map is short: a partial/over-broad store response (e.g. a stale id
        // padding the catalog to the same length) could otherwise wedge the
        // length check and leave kProSku permanently unresolved/unpurchasable.
        if (!_allSkus.every(_products.containsKey)) {
          final response = await iap.queryProductDetails(_allSkus);
          // Diagnostics: the plugin does NOT throw on a billing-level failure -
          // it returns empty productDetails with a non-null error and the bad
          // ids in notFoundIDs. Surface both so "products never loaded" can be
          // diagnosed instead of failing silently. kProSku is Apple-only and is
          // ALWAYS absent on Android, so exclude it from the not-found warning.
          if (response.error != null) {
            debugPrint(
                'Monetization: queryProductDetails error: ${response.error}');
          }
          final missing =
              response.notFoundIDs.where((id) => id != kProSku).toList();
          if (missing.isNotEmpty) {
            debugPrint('Monetization: products NOT FOUND in store '
                '(check Play Console: ids byte-match, status Active, '
                'allow propagation): $missing');
          }
          for (final product in response.productDetails) {
            _products[product.id] = product;
          }
        }
        // Restored purchases arrive on the purchase stream - the Flutter
        // analog of the original queryPurchases() in checkPurchases(). We
        // collect the SKUs they report so we can RECONCILE afterwards: a
        // donation tier the user refunded is no longer returned here, so it must
        // be dropped locally - otherwise its buy button stays disabled and they
        // can never donate that tier again. This runs ONLY after a SUCCESSFUL
        // restore (inside `if (_storeAvailable)`), so an offline / failed query
        // never wrongly strips a real supporter.
        final collector = <String>{};
        _restoreCollector = collector;
        await iap.restorePurchases();
        // restorePurchases() returns once the query is dispatched; the owned
        // purchases land on the stream slightly after. Give them a moment to
        // arrive (including the empty result = nothing owned) before reconciling.
        await Future<void>.delayed(const Duration(seconds: 2));
        _restoreCollector = null;
        await _reconcileOwned(collector);
      }
    } catch (e) {
      debugPrint('Monetization: store refresh failed: $e');
    }
    notifyListeners();
  }

  /// Launches the billing flow for one of [supportSkus].
  ///
  /// No-op when donation billing is unavailable (anything but the Android free
  /// build - donations are never sold on Apple, even on a gated Pro build),
  /// when the sku is unknown or already owned, or when its product details
  /// have not loaded. The entitlement is granted via the purchase stream, not
  /// by this method's completion. Failures surface on [lastUserMessage]
  /// (mirrors the original Snackbar on non-OK billing results).
  Future<void> buy(String sku) async {
    if (!isBillingAvailable || !_initialized) return;
    if (!supportSkus.contains(sku)) {
      debugPrint('Monetization: refusing to sell unknown sku "$sku"');
      return;
    }
    if (isOwned(sku)) return;
    final product = _products[sku];
    if (product == null) {
      debugPrint('Monetization: no product details for "$sku" yet');
      _postUserMessage(_catalogLoadingMessage);
      return;
    }
    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      debugPrint('Monetization: buy("$sku") failed: $e');
      _postUserMessage(_pendingMessage);
    }
  }

  /// Launches the billing flow for the Pro one-time unlock ([kProSku]).
  ///
  /// No-op unless [isProGated] (Apple + [kApplePurchasesEnabled]) and billing
  /// is live, when Pro is already owned, or when its product details have not
  /// loaded yet. The entitlement is granted via the purchase stream, not by
  /// this method's completion. Failures surface on [lastUserMessage].
  Future<void> buyPro() async {
    if (!_isActivePlatform || !_initialized || !isProGated) return;
    if (isProUnlocked) return;
    final product = _products[kProSku];
    if (product == null) {
      debugPrint('Monetization: no product details for "$kProSku" yet');
      _postUserMessage(_catalogLoadingMessage);
      return;
    }
    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      debugPrint('Monetization: buyPro() failed: $e');
      _postUserMessage(_pendingMessage);
    }
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Record what Play currently reports as owned (drives reconciliation).
          _restoreCollector?.add(purchase.productID);
          await _grant(purchase.productID);
        case PurchaseStatus.pending:
          // The original only logged "Purchase pending" here; the Snackbar
          // copy (confusingly) belongs to the error branch below.
          debugPrint('Monetization: purchase pending: ${purchase.productID}');
        case PurchaseStatus.canceled:
          // USER_CANCELED branch: logs only, no user message.
          debugPrint('Monetization: purchase canceled: ${purchase.productID}');
        case PurchaseStatus.error:
          debugPrint('Monetization: purchase error: ${purchase.error}');
          _postUserMessage(_pendingMessage);
      }
      // Unlike the original (which acknowledged even pending purchases - a
      // billing error), only complete purchases the store marked completable.
      if (purchase.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(purchase);
        } catch (e) {
          debugPrint('Monetization: completePurchase failed: $e');
        }
      }
    }
  }

  /// Grants ownership of [sku]. Entitlements are ADDED here on purchase/restore;
  /// the ONLY removal is [_reconcileOwned] dropping a purchase Play no longer
  /// reports (a refund/revoke), and only after a successful restore.
  Future<void> _grant(String sku) async {
    if (!_allSkus.contains(sku) || _owned.contains(sku)) return;
    _owned.add(sku);
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setStringList(_ownedSkusPrefKey, _owned.toList()..sort());
    } catch (e) {
      debugPrint('Monetization: failed to persist entitlement: $e');
    }
    notifyListeners();
  }

  /// Reconciles [_owned] with what Play currently reports as owned ([ownedNow],
  /// gathered during a SUCCESSFUL restore): drops any locally-cached entitlement
  /// Play no longer returns - i.e. a refunded / revoked purchase - so its buy
  /// button re-enables and the user can purchase that tier again. Called ONLY
  /// after a successful restore (never on an offline / failed query), so a real
  /// supporter is never wrongly stripped by a transient outage. Persists +
  /// notifies only when something actually changed.
  Future<void> _reconcileOwned(Set<String> ownedNow) async {
    final revoked = _owned.where((sku) => !ownedNow.contains(sku)).toList();
    if (revoked.isEmpty) return;
    _owned.removeAll(revoked);
    debugPrint('Monetization: reconciled - dropped no-longer-owned: $revoked');
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setStringList(_ownedSkusPrefKey, _owned.toList()..sort());
    } catch (e) {
      debugPrint('Monetization: failed to persist reconciliation: $e');
    }
    notifyListeners();
  }

  void _postUserMessage(String message) {
    // Reset first so an identical repeated message still notifies listeners.
    _lastUserMessage.value = null;
    _lastUserMessage.value = message;
  }

  // ---------------------------------------------------------------------------
  // Test seams. None of these are referenced by production code; they exist so
  // tests can exercise BOTH gating states (and a mocked Pro purchase) without
  // depending on the [kApplePurchasesEnabled] compile-time const or on real
  // billing platform channels. Every call notifies listeners so the UI rebuilds
  // exactly as it would after a real store event.
  // ---------------------------------------------------------------------------

  /// Forces [isProGated] (`true`/`false`) or restores the production default
  /// (`null`). Test-only.
  @visibleForTesting
  void debugSetProGated(bool? gated) {
    _debugProGatedOverride = gated;
    notifyListeners();
  }

  /// Marks the Pro unlock as owned in-memory (no platform channel, no
  /// persistence), flipping [isProUnlocked]/[hasPro]. Mirrors what the purchase
  /// stream's grant does for the UI. Test-only.
  @visibleForTesting
  void debugGrantPro() {
    if (_owned.add(kProSku)) notifyListeners();
  }

  /// Seeds a fake [ProductDetails] for [kProSku] so [canBuyPro] is true and
  /// [proPrice] returns [price] while gating is on. Test-only.
  @visibleForTesting
  void debugSetProProduct(ProductDetails product) {
    _products[kProSku] = product;
    notifyListeners();
  }

  /// Clears every test override and the in-memory product/ownership/init state
  /// so process-singleton state never leaks between tests. Test-only.
  @visibleForTesting
  void debugReset() {
    _debugProGatedOverride = null;
    _owned.clear();
    _products.clear();
    _initialized = false;
    _storeAvailable = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _lastUserMessage.dispose();
    super.dispose();
  }
}
