class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.yourjamup.com', // change when ready
  );

  // If you want a quick toggle:
  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
}
