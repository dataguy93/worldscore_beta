class AppConfig {
  const AppConfig._();

  // Replace with your production domain once hosting is configured.
  static const String registrationBaseUrl = String.fromEnvironment(
    'REGISTRATION_BASE_URL',
    defaultValue: 'https://example.com',
  );
}
