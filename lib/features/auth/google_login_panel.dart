import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_controller.dart';
import 'google_button_stub.dart'
    if (dart.library.js_interop) 'google_button_web.dart'
    as platform;

Future<void>? _sdkReady;

Future<void> _initializeSdk(String clientId) => _sdkReady ??= GoogleSignIn
    .instance
    .initialize(clientId: clientId)
    .catchError((Object error) {
      _sdkReady = null;
      throw error;
    });

class GoogleLoginPanel extends StatefulWidget {
  const GoogleLoginPanel({super.key, required this.auth});
  final AuthController auth;

  @override
  State<GoogleLoginPanel> createState() => _GoogleLoginPanelState();
}

class _GoogleLoginPanelState extends State<GoogleLoginPanel> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  Widget? _button;
  String? _setupError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    const clientId = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');
    if (!kIsWeb) {
      setState(() {
        _loading = false;
        _setupError = '현재 Google 로그인은 웹에서 지원합니다.';
      });
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$')
        .hasMatch(clientId)) {
      setState(() {
        _loading = false;
        _setupError = 'Google 로그인 설정이 필요합니다. 실행 설정을 확인해 주세요.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _setupError = null;
    });
    try {
      await _initializeSdk(clientId).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      _subscription ??= GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            final token = event.user.authentication.idToken;
            if (token == null || token.isEmpty) {
              widget.auth.showProviderError('Google 인증을 다시 진행해 주세요.');
            } else {
              unawaited(widget.auth.loginWithGoogle(token));
            }
          }
        },
        onError: (Object error) {
          widget.auth.showProviderError(
            error is GoogleSignInException &&
                    error.code == GoogleSignInExceptionCode.canceled
                ? '로그인을 취소했습니다. 다시 시도할 수 있습니다.'
                : 'Google 로그인에 실패했습니다. 다시 시도해 주세요.',
          );
        },
      );
      final button = platform.buildGoogleButton();
      setState(() {
        _button = button;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _setupError = 'Google 로그인 서비스를 불러오지 못했습니다. 연결 상태를 확인해 주세요.';
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CircularProgressIndicator(semanticsLabel: 'Google 로그인 준비 중');
    }
    if (_setupError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_setupError!, textAlign: TextAlign.center),
          if (kIsWeb)
            TextButton(onPressed: _prepare, child: const Text('다시 시도')),
        ],
      );
    }
    return AbsorbPointer(
      absorbing: widget.auth.busy,
      child: ExcludeFocus(excluding: widget.auth.busy, child: _button!),
    );
  }
}
