import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'auth_api.dart';
import 'kakao_gateway.dart';

KakaoGateway createKakaoGateway() => _WebKakaoGateway();

class _WebKakaoGateway implements KakaoGateway {
  Completer<AuthSession>? _pending;
  web.Window? _popup;
  JSFunction? _listener;
  Timer? _timeout;
  Timer? _closed;
  Timer? _closedGrace;

  @override
  Future<AuthSession> login() {
    if (_pending != null) return _pending!.future;
    const baseUrl = String.fromEnvironment(
      'OSEE_API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.scheme != 'https' &&
            !(base.scheme == 'http' &&
                ['localhost', '127.0.0.1'].contains(base.host)))) {
      return Future.error(const AuthFailure('로그인 서버 주소 설정을 확인해 주세요.'));
    }
    final pending = Completer<AuthSession>();
    _pending = pending;
    try {
      _listener = ((web.Event raw) {
        final event = raw as web.MessageEvent;
        if (event.origin != base.origin || !identical(event.source, _popup)) {
          return;
        }
        try {
          final message = event.data.dartify();
          if (message is! Map || message['type'] != 'osee:kakao-login') return;
          _finish(session: decodeKakaoMessage(message));
        } on AuthFailure catch (failure) {
          _finish(failure: failure);
        } catch (_) {
          _finish(
            failure: const AuthFailure('카카오 로그인 응답을 확인하지 못했습니다. 다시 시도해 주세요.'),
          );
        }
      }).toJS;
      web.window.addEventListener('message', _listener);
      _popup = web.window.open(
        base.resolve('/api/auth/social/kakao/authorize').toString(),
        '_blank',
        'popup,width=480,height=720',
      );
      if (_popup == null) {
        _finish(
          failure: const AuthFailure('팝업이 차단되었습니다. 팝업을 허용한 뒤 다시 시도해 주세요.'),
        );
      } else {
        _timeout = Timer(
          const Duration(minutes: 3),
          () => _finish(
            failure: const AuthFailure('카카오 로그인 시간이 초과되었습니다. 다시 시도해 주세요.'),
          ),
        );
        _closed = Timer.periodic(const Duration(milliseconds: 300), (_) {
          if (_popup?.closed ?? false) {
            _closedGrace ??= Timer(
              const Duration(milliseconds: 600),
              () => _finish(
                failure: const AuthFailure('카카오 로그인을 취소했습니다. 다시 시도할 수 있습니다.'),
              ),
            );
          }
        });
      }
    } catch (_) {
      _finish(failure: const AuthFailure('카카오 로그인 창을 열지 못했습니다. 다시 시도해 주세요.'));
    }
    return pending.future;
  }

  void _finish({AuthSession? session, AuthFailure? failure}) {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    _timeout?.cancel();
    _closed?.cancel();
    _closedGrace?.cancel();
    _closedGrace = null;
    if (_listener != null) web.window.removeEventListener('message', _listener);
    _listener = null;
    _popup?.close();
    _popup = null;
    if (session != null) {
      pending.complete(session);
    } else {
      pending.completeError(
        failure ?? const AuthFailure('카카오 로그인을 완료하지 못했습니다.'),
      );
    }
  }

  @override
  void cancel() => _finish(failure: const AuthFailure('카카오 로그인을 취소했습니다.'));
}
