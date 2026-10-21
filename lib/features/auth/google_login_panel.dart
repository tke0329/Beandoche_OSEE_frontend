import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'auth_controller.dart';
import 'google_sdk.dart';
import 'google_button_stub.dart'
    if (dart.library.js_interop) 'google_button_web.dart'
    as platform;

class GoogleLoginPanel extends StatefulWidget {
  const GoogleLoginPanel({super.key, required this.auth});
  final AuthController auth;

  @override
  State<GoogleLoginPanel> createState() => _GoogleLoginPanelState();
}

class _GoogleLoginPanelState extends State<GoogleLoginPanel> {
  StreamSubscription<String?>? _subscription;
  Widget? _button;
  double? _buttonWidth;
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
      await initializeGoogleSdk(clientId).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      _subscription ??= googleCredentialEvents.listen((token) {
        if (token == null) {
          widget.auth.showProviderError('Google 인증을 다시 진행해 주세요.');
        } else {
          unawaited(widget.auth.loginWithGoogle(token));
        }
      });
      setState(() {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(1.0, 400.0);
        if (_button == null || _buttonWidth != width) {
          _buttonWidth = width;
          _button = platform.buildGoogleButton(
            width,
            onError: () {
              if (!mounted) return;
              setState(() {
                _button = null;
                _setupError = 'Google 로그인 버튼을 불러오지 못했습니다. 다시 시도해 주세요.';
              });
            },
          );
        }
        return SizedBox(
          width: width,
          height: 40,
          child: AbsorbPointer(
            absorbing: widget.auth.busy,
            child: ExcludeFocus(excluding: widget.auth.busy, child: _button!),
          ),
        );
      },
    );
  }
}
