## 2.0.0

Same API as AnalyticsKit for Swift and Android 2.0.0.

- Typed, immutable parameters: `AnalyticsValue` and `AnalyticsParameters` replace `Map<String, Object>`.
- Per-event routing: every provider declares a `ProviderID`; events, screens and purchases carry `Destinations` (`all`, `only`, `except`).
- Revenue: `Purchase` and `trackPurchase`; providers opt in with `RevenueTracking`.
- Screens: `ScreenView` and `trackScreen`; providers opt in with `ScreenTracking`, the rest get a `screen_view` event.
- `AnalyticsScope` gives `UiAnalytics` (`track`, `trackScreen`).
- Every public method documents when and why to call it.

Breaking: `AnalyticsProvider` requires `id`; parameters and user properties are `AnalyticsParameters`.

## 1.0.0

- Initial release: `AnalyticsService`, `CompositeAnalytics`, `AnalyticsProvider`, hashed user ID, `SharedPreferencesUserIDStore`, `AnalyticsScope`.
