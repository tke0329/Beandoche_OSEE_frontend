import 'package:flutter/material.dart';

import '../../core/theme/osee_theme.dart';
import 'auth_controller.dart';
import 'google_login_panel.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.auth});
  final AuthController auth;

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
                      Center(child: GoogleLoginPanel(auth: auth)),
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
                      const SizedBox(height: 24),
                      const Text(
                        '처음 로그인하면 OSEE 계정이 자동으로 생성됩니다.',
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
