# beandoche_osee_frontend

## OSEE 웹 Google 로그인 실행

1. `flutter pub get`을 실행한다.
2. `config/development.example.json`을 프로젝트 루트의 `.env.json`으로 복사한다.
3. `GOOGLE_OAUTH_CLIENT_ID`에 백엔드와 동일한 **웹 OAuth Client ID**를 설정한다. Client Secret은 넣지 않는다.
4. 백엔드 저장소에서 PostgreSQL과 Spring을 실행한다. 기본 API 주소는 `http://localhost:8080`이다.
5. 프론트 저장소에서 실행한다.

```powershell
.\scripts\run-web.ps1
```

직접 실행할 경우:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 5173 --dart-define-from-file=.env.json
```

Google Cloud의 승인된 JavaScript 원본에는 `http://localhost`와 `http://localhost:5173`을 등록한다. 웹 공식 버튼에서 ID Token을 받는 흐름이므로 백엔드 Google callback URI는 사용하지 않는다.

`.env.json`은 Git에서 제외한다. Client ID와 API 주소는 공개 빌드 설정이며, 비밀키나 Refresh Token을 빌드 설정에 넣지 않는다. 종료는 실행 터미널에서 `q` 또는 `Ctrl+C`를 사용한다.

현재 인증 상태는 `AuthController`(ChangeNotifier)와 `AuthScope`로 공유한다. 백엔드 토큰 발급 성공 후에만 홈을 표시하며, 처리된 오류는 로그인 화면에서 안내한다. 토큰은 메모리에서만 관리하므로 새로고침하면 다시 로그인한다. Access Token 만료 시 로그인 화면으로 돌아간다. **48시간 영속 로그인, 자동 재발급, 서버 로그아웃은 후속 구현 대상**이다. 모바일 Google 로그인 설정도 후속 작업이다.

기존 옷장·착장 화면은 로컬 데모 상태를 사용한다. 인증 게이트 추가가 사용자별 서버 데이터 연동 완료를 의미하지 않는다.

검증:

```powershell
flutter analyze
flutter test
flutter build web --dart-define-from-file=.env.json
```

공식 연동 방식: [google_sign_in_web](https://pub.dev/packages/google_sign_in_web)

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
