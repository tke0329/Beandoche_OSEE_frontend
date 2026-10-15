import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key, required this.userId, required this.onHome});
  final int userId;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MY PAGE',
              style: TextStyle(color: faded, letterSpacing: 2, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              '내 계정',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'OSEE에서 나에게 맞는 핏을 찾아보세요.',
              style: TextStyle(color: faded),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.person_outline, size: 30),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'OSEE 회원',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '회원 ID: $userId',
                      style: const TextStyle(color: faded),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      '닉네임',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '닉네임을 설정하고 변경하는 기능을 준비하고 있어요.',
                      style: TextStyle(color: faded, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const OutlinedButton(
                      onPressed: null,
                      child: Text('닉네임 설정 준비 중'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.accessibility_new_outlined,
                      color: point,
                      size: 32,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '나의 신체정보와 아바타',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '신체 치수를 등록하고 내 체형을 담은 아바타를 만드는 기능을 준비하고 있어요.',
                      style: TextStyle(color: faded, height: 1.6),
                    ),
                    SizedBox(height: 16),
                    FilledButton(onPressed: null, child: Text('신체정보 등록 준비 중')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
