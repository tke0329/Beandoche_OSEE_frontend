import 'auth_api.dart';

abstract interface class KakaoGateway {
  Future<AuthSession> login();
  void cancel();
}

AuthSession decodeKakaoMessage(Object? value) {
  if (value case {
    'type': 'osee:kakao-login',
    'result': {'ok': true, 'session': Object session},
  }) {
    return AuthSession.fromJson(session);
  }
  if (value case {
    'type': 'osee:kakao-login',
    'result': {'ok': false, 'code': String code},
  }) {
    throw AuthFailure(switch (code) {
      'KAKAO_CANCELED' => '카카오 로그인을 취소했습니다. 다시 시도할 수 있습니다.',
      'KAKAO_NOT_CONFIGURED' => '카카오 로그인 설정이 필요합니다. 관리자에게 문의해 주세요.',
      'KAKAO_STATE_INVALID' => '로그인 요청이 만료되었습니다. 다시 시도해 주세요.',
      'ACCOUNT_NOT_ALLOWED' => '이 계정으로 로그인할 수 없습니다.',
      'KAKAO_UNAVAILABLE' => '카카오 로그인 서비스를 잠시 이용할 수 없습니다. 다시 시도해 주세요.',
      _ => '카카오 로그인에 실패했습니다. 다시 시도해 주세요.',
    });
  }
  throw const AuthFailure('로그인 응답을 확인하지 못했습니다. 다시 시도해 주세요.');
}
