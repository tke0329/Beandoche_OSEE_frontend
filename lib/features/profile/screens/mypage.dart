import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';
import '../../auth/auth_controller.dart';
import '../profile_avatar.dart';
import 'profile_form_page.dart';
import 'body_setup_page.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key, required this.userId, required this.onHome});
  final int userId;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final profile = auth.profile;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'MY PAGE',
                style: TextStyle(color: faded, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              const Text(
                '내 계정',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileAvatar(image: profile?.image, radius: 40),
                      const SizedBox(height: 20),
                      Text(
                        profile?.nickname ?? 'OSEE 회원',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '회원 ID: $userId',
                        style: const TextStyle(color: faded),
                      ),
                      if (profile?.nextNicknameChange != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '다음 닉네임 변경: ${profile!.nextNicknameChange!.toLocal().toString().split('.').first}',
                          ),
                        ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: auth.busy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => ProfileFormPage(
                                    auth: auth,
                                    onDone: () => Navigator.of(context).pop(),
                                  ),
                                ),
                              ),
                        child: const Text('프로필 수정'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.accessibility_new_outlined,
                        color: point,
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '나의 신체정보와 아바타',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('아직 준비 중입니다. 지금은 신체정보를 수집하지 않아요.'),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => BodySetupPage(
                              onNext: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        child: const Text('체형정보 설정'),
                      ),
                    ],
                  ),
                ),
              ),
              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(auth.error!),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: auth.busy ? null : auth.logout,
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
              ),
              TextButton.icon(
                onPressed: onHome,
                icon: const Icon(Icons.arrow_back),
                label: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
