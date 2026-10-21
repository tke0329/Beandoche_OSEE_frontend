import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../auth/credential_client_stub.dart'
    if (dart.library.js_interop) '../../auth/credential_client_web.dart'
    as platform;

class WithdrawalCompletePage extends StatelessWidget {
  const WithdrawalCompletePage({super.key, required this.auth});
  final AuthController auth;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle_outline, size: 64),
              const SizedBox(height: 24),
              const Text(
                '회원탈퇴가 완료되었습니다.',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              const Text('프로필과 사진을 삭제하고 모든 로그인 세션을 종료했습니다.'),
              if (auth.withdrawalResult?.googleUnlinkInProgress ?? false) ...[
                const SizedBox(height: 24),
                const LinearProgressIndicator(semanticsLabel: 'Google 연결 해제 중'),
                const Text('Google 연결을 자동으로 해제하고 있습니다.'),
              ] else if (auth.withdrawalResult?.googleUnlinked ?? false) ...[
                const SizedBox(height: 24),
                const Text('Google 계정 연결도 자동으로 해제했습니다.'),
              ] else if (auth.withdrawalResult?.googleUnlinkRequired ??
                  false) ...[
                const SizedBox(height: 24),
                const Text(
                  'Google 자동 연결 해제를 완료하지 못했습니다. 계정 설정에서 OSEE 연결을 직접 삭제해 주세요.',
                ),
                TextButton(
                  onPressed: platform.openGoogleConnections,
                  child: const Text('Google 계정 연결 설정 열기'),
                ),
                const SelectableText(
                  'https://myaccount.google.com/connections',
                ),
              ],
              if (auth.withdrawalResult?.completionWarning
                  case final String warning)
                Text(warning),
              if (auth.withdrawalResult?.kakaoUnlinkPending ?? false) ...[
                const SizedBox(height: 24),
                const Text(
                  '카카오 연결 해제는 별도로 처리됩니다. OSEE 회원탈퇴는 완료되었으며, 연결 해제 전에는 같은 카카오 계정 재가입이 제한될 수 있습니다.',
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed:
                    (auth.withdrawalResult?.googleUnlinkInProgress ?? false)
                    ? null
                    : auth.finishWithdrawal,
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
