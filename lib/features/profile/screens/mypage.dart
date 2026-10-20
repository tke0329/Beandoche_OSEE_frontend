import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';
import '../../auth/auth_controller.dart';
import '../profile_avatar.dart';
import 'profile_form_page.dart';
import 'body_setup_page.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key, required this.onHome});
  final VoidCallback onHome;

  Future<void> confirmWithdrawal(
    BuildContext context,
    AuthController auth,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('정말 탈퇴하시겠어요?'),
        content: const Text(
          '프로필과 사진이 삭제되고 모든 기기의 로그인 세션이 종료됩니다. 삭제한 정보는 복구할 수 없습니다.\n\n소셜 계정 자체는 삭제되지 않습니다. Google 연결은 탈퇴 후 계정 설정에서 직접 해제해야 합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffb3261e),
            ),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.withdraw();
  }

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
              const SizedBox(height: 20),
              TextButton(
                onPressed: auth.busy
                    ? null
                    : () => confirmWithdrawal(context, auth),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xffb3261e),
                ),
                child: const Text('회원탈퇴'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
