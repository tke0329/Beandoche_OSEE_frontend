import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../profile/profile_data.dart';
import 'auth_api.dart';
import 'kakao_gateway.dart';
import 'kakao_gateway_stub.dart'
    if (dart.library.js_interop) 'kakao_gateway_web.dart'
    as platform;

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
  AuthController({AuthApi? api, KakaoGateway? kakaoGateway})
    : _api = api ?? AuthApi(),
      _kakao = kakaoGateway ?? platform.createKakaoGateway();
  final AuthApi _api;
  final KakaoGateway _kakao;
  AuthSession? _session;
  AuthSession? get session => _session;
  ProfileData? profile;
  bool get isAuthenticated =>
      _session != null &&
      _session!.accessTokenExpiresAt.isAfter(DateTime.now());
  bool busy = false;
  bool restoring = false;
  bool showBodyStep = false;
  String? error;
  bool _disposed = false;
  Timer? _expiry;
  Future<void>? _restoration;

  Future<void> loginWithGoogle(String idToken) =>
      _login(() => _api.loginWithGoogle(idToken));
  Future<void> loginWithKakao() => _login(_kakao.login);

  Future<void> _login(Future<AuthSession> Function() authenticate) async {
    if (busy || _disposed || isAuthenticated || restoring) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await authenticate();
      if (_disposed) return;
      _session = result;
      profile = null;
      _schedule();
      await _loadProfile();
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

  Future<void> restore() {
    if (_disposed) return Future.value();
    return _restoration ??= _restore().whenComplete(() => _restoration = null);
  }

  Future<void> _restore() async {
    restoring = true;
    error = null;
    notifyListeners();
    try {
      final restored = await _api.restore();
      if (_disposed) return;
      _session = restored;
      if (restored == null) {
        profile = null;
        showBodyStep = false;
        _expiry?.cancel();
      } else {
        _schedule();
        if (profile == null || profile!.userId != restored.userId) {
          await _loadProfile();
        }
      }
    } on AuthFailure catch (failure) {
      if (!_disposed) {
        error = failure.message;
        if (!isAuthenticated) {
          _session = null;
          profile = null;
        } else {
          _expiry?.cancel();
          _expiry = Timer(
            const Duration(seconds: 15),
            () => unawaited(restore()),
          );
        }
      }
    } catch (_) {
      if (!_disposed) {
        _session = null;
        profile = null;
        error = '로그인 상태를 확인하지 못했습니다. 다시 시도해 주세요.';
      }
    } finally {
      if (!_disposed) {
        restoring = false;
        notifyListeners();
      }
    }
  }

  void _schedule() {
    _expiry?.cancel();
    final delay =
        _session!.accessTokenExpiresAt.difference(DateTime.now()) -
        const Duration(seconds: 30);
    _expiry = Timer(
      delay.isNegative ? const Duration(seconds: 1) : delay,
      () => unawaited(restore()),
    );
  }

  Future<void> _loadProfile() async {
    final userId = _session?.userId;
    if (_session == null) return;
    try {
      final value = await _api.profile(_session!.accessToken);
      if (!_disposed && _session?.userId == userId) profile = value;
    } on AuthFailure catch (failure) {
      if (!_disposed) error = failure.message;
    }
  }

  Future<void> reloadProfile() async {
    if (busy || !isAuthenticated) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _loadProfile();
    } catch (_) {
      if (!_disposed) error = '프로필을 불러오지 못했습니다. 다시 시도해 주세요.';
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<bool> saveProfile(
    String nickname, {
    Uint8List? image,
    String? imageName,
    bool removeImage = false,
  }) async {
    if (busy || !isAuthenticated) return false;
    final userId = _session!.userId;
    final initial = !(profile?.completed ?? false);
    busy = true;
    error = null;
    notifyListeners();
    try {
      final saved = await _api.saveProfile(
        _session!.accessToken,
        nickname,
        image: image,
        imageName: imageName,
        removeImage: removeImage,
      );
      if (_disposed || _session?.userId != userId) return false;
      profile = saved;
      showBodyStep = initial;
      return true;
    } on AuthFailure catch (failure) {
      if (!_disposed) error = failure.message;
      return false;
    } catch (_) {
      if (!_disposed) error = '프로필을 저장하지 못했습니다. 다시 시도해 주세요.';
      return false;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (_restoration != null) await _restoration;
      if (_disposed) return;
      await _api.logout();
      if (_disposed) return;
      _session = null;
      profile = null;
      showBodyStep = false;
      _expiry?.cancel();
    } on AuthFailure catch (failure) {
      if (!_disposed) error = failure.message;
    } catch (_) {
      if (!_disposed) error = '로그아웃하지 못했습니다. 연결 상태를 확인해 주세요.';
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void finishBodyStep() {
    showBodyStep = false;
    notifyListeners();
  }

  void showProviderError(String message) {
    if (!_disposed && !busy && !isAuthenticated) {
      error = message;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expiry?.cancel();
    _kakao.cancel();
    _session = null;
    _api.close();
    super.dispose();
  }
}
