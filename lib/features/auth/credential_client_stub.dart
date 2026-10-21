import 'package:http/http.dart' as http;

http.Client credentialClient() => http.Client();
Future<T> sessionOperation<T>(String name, Future<T> Function() work) => work();
void Function() watchSessionEnd(void Function() onEnd) => () {};
void publishSessionEnd() {}
void openGoogleConnections() {}
