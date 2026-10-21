import 'auth_api.dart';
import 'kakao_gateway.dart';

KakaoGateway createKakaoGateway() => _UnsupportedKakaoGateway();

class _UnsupportedKakaoGateway implements KakaoGateway {
  @override
  Future<AuthSession> login() async =>
      throw const AuthFailure('카카오 로그인은 웹에서 먼저 지원합니다.');
  @override
  void cancel() {}
}
