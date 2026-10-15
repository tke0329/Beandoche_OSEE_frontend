import 'dart:async';

import 'package:flutter/widgets.dart';

import 'auth_api.dart';

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
}

class AuthController extends ChangeNotifier {
  AuthController({AuthApi? api}) : _api = api ?? AuthApi();
  final AuthApi _api;
  AuthSession? _session;
  AuthSession? get session => _session;
  bool get isAuthenticated =>
      _session != null &&
      _session!.accessTokenExpiresAt.isAfter(DateTime.now());
  bool busy = false;
  String? error;
  bool _disposed = false;
  Timer? _expiry;

  Future<void> loginWithGoogle(String idToken) async {
    if (busy || _disposed || isAuthenticated) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await _api.loginWithGoogle(idToken);
      if (_disposed) return;
      _session = result;
      _expiry?.cancel();
      _expiry = Timer(
        result.accessTokenExpiresAt.difference(DateTime.now()),
        () {
          _session = null;
          error = '로그인이 만료되었습니다. 다시 로그인해 주세요.';
          notifyListeners();
        },
      );
    } on AuthFailure catch (failure) {
      if (!_disposed) error = failure.message;
    } catch (_) {
      if (!_disposed) error = '로그인을 완료하지 못했습니다. 다시 시도해 주세요.';
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void showProviderError(String message) {
    if (_disposed || busy || isAuthenticated) return;
    error = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _expiry?.cancel();
    _session = null;
    _api.close();
    super.dispose();
  }
}
