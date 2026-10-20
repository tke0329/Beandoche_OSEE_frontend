import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

http.Client credentialClient() => BrowserClient()..withCredentials = true;

Future<T> sessionOperation<T>(String name, Future<T> Function() work) async {
  final locks = web.window.navigator.getProperty<JSAny?>('locks'.toJS);
  if (locks == null) return work();
  late T result;
  Future<JSAny?> execute() async {
    result = await work();
    return null;
  }

  await web.window.navigator.locks
      .request(name, ((web.Lock? _) => execute().toJS).toJS)
      .toDart;
  return result;
}

void Function() watchSessionEnd(void Function() onEnd) {
  final channel = web.BroadcastChannel('osee-session');
  channel.onmessage = ((web.MessageEvent event) {
    if (event.data.dartify() == 'signed-out') onEnd();
  }).toJS;
  return () => channel.close();
}

void publishSessionEnd() {
  final channel = web.BroadcastChannel('osee-session');
  channel.postMessage('signed-out'.toJS);
  channel.close();
}

void openGoogleConnections() {
  web.window.open(
    'https://myaccount.google.com/connections',
    '_blank',
    'noopener,noreferrer',
  );
}
