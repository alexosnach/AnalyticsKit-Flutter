/// Names one analytics provider, so events can be routed to it.
///
/// The library ships no list of providers: each provider declares its own ID
/// next to its adapter, so adding a provider never touches this library.
///
/// ```dart
/// abstract final class Providers {
///   static const amplitude = ProviderID('amplitude');
/// }
/// ```
///
/// An extension type over `String`: compared by its text, and usable in
/// `const` sets such as `Destinations.only({Providers.amplitude})`.
extension type const ProviderID(String rawValue) {}
