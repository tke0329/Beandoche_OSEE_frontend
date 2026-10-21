import 'package:google_sign_in/google_sign_in.dart';

Future<void>? _ready;
Future<void> initializeGoogleSdk(String clientId) => _ready ??= GoogleSignIn
    .instance
    .initialize(clientId: clientId)
    .catchError((Object error) {
      _ready = null;
      throw error;
    });
