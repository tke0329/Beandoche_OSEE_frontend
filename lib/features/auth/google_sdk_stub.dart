Stream<String?> get googleCredentialEvents => const Stream.empty();

Future<void> initializeGoogleSdk(String clientId) =>
    Future.error(UnsupportedError('Google login is currently web-only.'));
