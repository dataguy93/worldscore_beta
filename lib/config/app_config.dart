/// App-wide configuration values.
///
/// Course-name autocomplete is served by our own Cloud Run backend, which
/// proxies Google Places (New) and keeps the Places API key server-side (in
/// Secret Manager) instead of shipping it in the app. [placesAutocompleteUrl]
/// points at that proxy endpoint.
///
/// Override the base URL at build time if needed:
///   `--dart-define=WORLDSCORE_API_BASE=https://...`
///
/// When the URL is empty the course picker still works as a plain text field
/// (and still suggests previously-used courses from Firestore); it just can't
/// fetch new courses from Google.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'WORLDSCORE_API_BASE',
    defaultValue: 'https://worldscore-985255509017.us-east1.run.app',
  );

  static String get placesAutocompleteUrl =>
      apiBaseUrl.isEmpty ? '' : '$apiBaseUrl/places/autocomplete';

  static bool get placesSearchEnabled => placesAutocompleteUrl.isNotEmpty;
}
