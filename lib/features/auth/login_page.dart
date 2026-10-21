import 'package:flutter/material.dart';

import '../../core/theme/osee_theme.dart';
import 'auth_controller.dart';
import 'google_login_panel.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.auth, this.onHome});
  final AuthController auth;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 56 : 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: ListenableBuilder(
                  listenable: auth,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onHome != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: onHome,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('홈으로 돌아가기'),
                          ),
                        ),
                      const Text(
                        'OSEE',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -4,
                        ),
                      ),
                      const SizedBox(height: 52),
                      const Text(
                        '나에게 맞는 옷을 만나는 시작',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '내 체형을 담은 아바타로\n구매 전, 나만의 핏을 확인해 보세요.',
                        style: TextStyle(
                          color: faded,
                          fontSize: 16,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 44),
                      const Text(
                        '로그인 / 회원가입',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      GoogleLoginPanel(auth: auth),
                      const SizedBox(height: 14),
                      FilledButton(
                        key: const ValueKey('kakao-login-button'),
                        onPressed: auth.busy ? null : auth.loginWithKakao,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xfffee500),
                          foregroundColor: const Color(0xff191919),
                          minimumSize: const Size(0, 40),
                          fixedSize: const Size.fromHeight(40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const StadiumBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 12,
                              child: Icon(Icons.chat_bubble, size: 18),
                            ),
                            Center(child: Text('카카오로 계속하기')),
                          ],
                        ),
                      ),
                      if (auth.busy) ...[
                        const SizedBox(height: 20),
                        const LinearProgressIndicator(
                          semanticsLabel: '로그인 확인 중',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '로그인을 확인하고 있습니다.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: Text(
                          '로그인은 최초 로그인부터 최대 48시간 유지됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: faded, fontSize: 12),
                        ),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 20),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            auth.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      if (auth.error != null)
                        TextButton(
                          onPressed: auth.busy || auth.restoring
                              ? null
                              : auth.restore,
                          child: const Text('로그인 상태 다시 확인'),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        '닉네임을 비우면 OSEE_랜덤번호로 시작해요.\n프로필 사진은 나중에 추가해도 괜찮아요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: faded,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          if (!wide) return form;
          return Row(
            children: [
              Expanded(
                child: Container(
                  color: OseePalette.primary800,
                  padding: const EdgeInsets.all(64),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.accessibility_new_rounded,
                        size: 88,
                        color: OseePalette.primary200,
                      ),
                      SizedBox(height: 40),
                      Text(
                        'Your body.\nYour fit.\nYour OSEE.',
                        style: TextStyle(
                          fontFamily: 'CrimsonPro',
                          fontSize: 64,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 28),
                      Text(
                        '입어보기 전의 확신',
                        style: TextStyle(
                          fontSize: 18,
                          color: OseePalette.primary200,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: form),
            ],
          );
        },
      ),
    ),
  );
}
