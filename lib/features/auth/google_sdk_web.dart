import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('google.accounts.id.initialize')
external void _initialize(JSObject configuration);

final _credentials = StreamController<String?>.broadcast();
Stream<String?> get googleCredentialEvents => _credentials.stream;
Future<void>? _ready;
String? _clientId;

Future<void> initializeGoogleSdk(String clientId) {
  if (_clientId != null && _clientId != clientId) {
    return Future.error(StateError('Google client configuration changed.'));
  }
  _clientId = clientId;
  return _ready ??= _loadAndInitialize(clientId).catchError((Object error) {
    _ready = null;
    _clientId = null;
    throw error;
  });
}

Future<void> _loadAndInitialize(String clientId) async {
  final loaded = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src = 'https://accounts.google.com/gsi/client'
    ..async = true;
  final onLoad = script.onLoad.listen((_) {
    if (!loaded.isCompleted) loaded.complete();
  });
  final onError = script.onError.listen((_) {
    if (!loaded.isCompleted) {
      loaded.completeError(StateError('Google SDK could not be loaded.'));
    }
  });
  web.document.head!.appendChild(script);
  try {
    await loaded.future.timeout(const Duration(seconds: 12));
    _initialize(
      {
            'client_id': clientId,
            // Prompt FedCM does not enable the button flow. Explicitly opt in here.
            'use_fedcm_for_button': true,
            'button_auto_select': false,
            'auto_select': false,
            'callback': ((JSAny? response) {
              final result = response.dartify();
              final token = result is Map ? result['credential'] : null;
              _credentials.add(
                token is String && token.isNotEmpty ? token : null,
              );
            }).toJS,
          }.jsify()!
          as JSObject,
    );
  } catch (_) {
    script.remove();
    rethrow;
  } finally {
    await onLoad.cancel();
    await onError.cancel();
  }
}
