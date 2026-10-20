import 'package:flutter/material.dart';

class BodySetupPage extends StatelessWidget {
  const BodySetupPage({super.key, required this.onNext});
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('체형정보 설정')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.accessibility_new,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 28),
              const Text(
                '아직 준비 중입니다',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              const Text(
                '내 체형을 반영한 아바타 기능을 준비하고 있어요.\n지금은 신체정보를 입력하지 않고 다음으로 진행해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.7),
              ),
              const SizedBox(height: 32),
              FilledButton(onPressed: onNext, child: const Text('다음')),
            ],
          ),
        ),
      ),
    ),
  );
}
