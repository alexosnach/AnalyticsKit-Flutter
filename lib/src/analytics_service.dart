import 'analytics_event.dart';
import 'analytics_value.dart';
import 'identifier_hasher.dart';
import 'purchase.dart';
import 'screen_view.dart';

/// Reports what happens in the app.
abstract interface class EventTracking {
  /// Sends one event to the providers its [AnalyticsEvent.destinations] include.
  ///
  /// Call it at the moment the thing happened — a screen shown, a button
  /// tapped, a step finished. Returns immediately and never throws:
  /// delivery is the SDKs' job.
  ///
  /// ```dart
  /// analytics.track(const AnalyticsEvent(
  ///   name: 'paywall_shown',
  ///   parameters: {'source': AnalyticsValue.string('onboarding')},
  /// ));
  /// ```
  void track(AnalyticsEvent event);
}

/// Reports which screens the user opens.
///
/// The app calls it on the service. A provider implements it only when its SDK
/// has its own screen API (Firebase's `screen_view`, UXCam's screen tags);
/// every other provider receives [ScreenView.fallbackEvent] through
/// [EventTracking.track], so no provider misses a screen.
abstract interface class ScreenTracking {
  /// Records that the user opened a screen.
  ///
  /// Call it once each time the screen becomes visible — from the screen
  /// state's `initState`/`didChangeDependencies` or a route observer —
  /// including when the user comes back to it. Don't call it from `build`
  /// (it runs many times), for dialogs or bottom sheets that aren't screens
  /// in your funnels, and don't send a separate event for the same visit.
  ///
  /// ```dart
  /// analytics.trackScreen(const ScreenView(name: 'paywall', screenClass: 'PaywallScreen'));
  /// ```
  void trackScreen(ScreenView screen);
}

/// What the UI gets through `AnalyticsScope`: events and screens, nothing else.
/// Identifying the user and revenue stay out of the UI.
abstract interface class UiAnalytics implements EventTracking, ScreenTracking {}

/// Records revenue.
///
/// The app calls it on the service; a provider implements it only when its SDK
/// records revenue. Providers that don't simply never see purchases.
abstract interface class RevenueTracking {
  /// Records one completed purchase as revenue.
  ///
  /// Call it once per transaction, after the store has confirmed it — for
  /// `in_app_purchase`, when a `PurchaseDetails` arrives with status
  /// `purchased` and is verified, before `completePurchase`. Don't call it
  /// for `restored` purchases or renewals the store re-delivers, or revenue
  /// is counted twice. Don't also send a separate "purchase" event for the
  /// same revenue: providers record it from this call.
  void trackPurchase(Purchase purchase);
}

/// Says who the user is, so every provider attributes events to the same person.
///
/// Calls go to every provider, regardless of any destinations.
abstract interface class UserIdentification {
  /// Ties the events that follow to this user.
  ///
  /// Call it at launch with the ID you already have (anonymous or signed-in)
  /// and again right after sign-in. The ID must be hashed: create it with an
  /// [IdentifierHasher] or get it from a `UserIDProvider`.
  void setUserID(HashedUserID id);

  /// Sets attributes of the user that providers attach to all later events,
  /// such as a plan or a cohort. Keys not passed keep their earlier values.
  ///
  /// Call it when an attribute changes, not before every event. Never put
  /// personal data (email, name, health data) in properties.
  void setUserProperties(AnalyticsParameters properties);

  /// Forgets the current user: their ID and properties.
  ///
  /// Call it on sign-out or account deletion, so the next person's events
  /// aren't attributed to them. Then call [setUserID] with the new ID.
  void reset();
}

/// Everything the app can do with analytics, as one dependency.
///
/// Build it once in the Composition Root (usually a `CompositeAnalytics`) and
/// inject it. Give each caller only the role it needs: a screen or view model
/// that reports events depends on [EventTracking] (and [ScreenTracking] if it
/// reports screens), the purchase flow on [RevenueTracking], sign-in/sign-out
/// code on [UserIdentification].
abstract interface class AnalyticsService
    implements UiAnalytics, RevenueTracking, UserIdentification {}
