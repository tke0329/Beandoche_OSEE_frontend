# beandoche_osee_frontend

## OSEE 웹 Google 로그인 실행

1. `flutter pub get`을 실행한다.
   Windows에서 심볼릭 링크 권한 안내가 나오면 Windows 설정의 개발자 모드를 활성화한 뒤 다시 실행한다. 데스크톱 플러그인 링크 권한과 웹 로그인 오류는 별개다.
2. 프로젝트 루트의 `.env.example`을 `.env`로 복사한다 (`Copy-Item .env.example .env`).
3. `GOOGLE_OAUTH_CLIENT_ID`에 백엔드와 동일한 **웹 OAuth Client ID**를 설정한다. Client Secret은 넣지 않는다.
4. 백엔드 저장소에서 PostgreSQL과 Spring을 실행한다. 기본 API 주소는 `http://localhost:8080`이다.
5. 프론트 저장소에서 실행한다.

macOS / Linux:

```bash
./scripts/run-web.sh
```

`.env`를 우선 사용하며, 기존 `.env.json`도 지원한다. 서버 준비가 끝나면 브라우저에서 `http://localhost:5173`을 직접 연다. 웹 서버 방식으로 실행한다.

Windows PowerShell:

```powershell
.\scripts\run-web.ps1
```

직접 실행할 경우:

```powershell
flutter run -d web-server --web-hostname localhost --web-port 5173 --dart-define-from-file=.env
```

서버가 준비되면 평소 사용하는 브라우저에서 `http://localhost:5173`을 연다. 로그인 유지 확인은 같은 브라우저 프로필로 진행한다. `flutter run -d chrome`의 디버그 Chrome은 임시 프로필과 프로젝트 캐시를 사용하므로 일반 브라우저의 쿠키와 별개이며, 종료 방식에 따라 복원이 달라질 수 있다. 시크릿 모드나 종료 시 쿠키 삭제 설정에서는 로그인 유지가 보장되지 않는다.

`web_dev_config.yaml`은 개발 서버 응답에 `Cross-Origin-Opener-Policy: same-origin-allow-popups`를 설정한다. Google·Kakao 로그인 팝업과 원래 화면의 통신을 허용하기 위한 설정이며 서버 재시작 후 적용된다. 배포 서버/CDN에서도 HTML 응답에 같은 헤더를 별도로 설정해야 한다. `index.html`의 meta 태그나 백엔드 API 헤더로 대신할 수 없다. `--web-enable-cross-origin-isolation`은 다른 격리 정책을 적용하므로 로그인 팝업과 함께 사용하기 전에 호환성을 검증한다. Google 또는 브라우저가 자체 정책으로 출력하는 경고는 앱 예외와 구분하며 콘솔 출력을 숨기지 않는다. [Google COOP 설정 안내](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid#cross_origin_opener_policy).

기본 진입 화면은 공개 홈이다. 헤더 프로필 영역의 로그인 버튼을 누르면 로그인 화면으로 이동한다. 개인 화면은 로그인이 필요하며 로그아웃하면 공개 홈으로 돌아간다. 앱 재접속 및 브라우저 복귀 시 HttpOnly 쿠키로 서버 세션을 확인한다.

Google Cloud의 승인된 JavaScript 원본에는 `http://localhost`와 `http://localhost:5173`을 등록한다. 웹 공식 버튼에서 ID Token을 받는 흐름이므로 백엔드 Google callback URI는 사용하지 않는다.

`.env`는 JSON이 아닌 `KEY=VALUE` 형식이며 Git에서 제외한다. `.env.example`만 공유한다. Flutter의 `--dart-define-from-file=.env`로 기존 `String.fromEnvironment`에 주입하므로 별도 dotenv 패키지나 런타임 파일 로딩은 필요 없다. Client ID와 API 주소는 공개 빌드 설정이며, 비밀키나 Refresh Token을 빌드 설정에 넣지 않는다. 종료는 실행 터미널에서 `q` 또는 `Ctrl+C`를 사용한다.

현재 인증 상태는 `AuthController`(ChangeNotifier)와 `AuthScope`로 공유한다. 웹은 HttpOnly 쿠키를 이용해 초기 진입 시 세션을 복원하고 Access Token 만료 전에 회전한다. 최대 유지 시간은 최초 로그인부터 48시간이며 재발급으로 늘어나지 않는다. Refresh Token 원문은 Dart·localStorage에 저장하지 않는다. 로그아웃은 서버 토큰을 무효화하고 쿠키와 화면 상태를 정리한다. 모바일 네이티브 OAuth·세션 저장 방식은 별도 작업이다.

프로필이 없는 계정은 최초 입력 화면으로 이동한다. 닉네임은 한글·영문·숫자·밑줄 2~20자이며 중복을 허용하지 않는다. 최초 닉네임을 비우면 서버에서 `OSEE_`와 랜덤 숫자 9자리로 생성한다. 입력 중 서버의 인증된 `GET /api/users/me/nickname-availability?nickname=...`로 중복과 금칙어를 확인하며 검사 중/오류 시 저장 버튼을 비활성화하고 빨간 필드 오류를 표시한다. 실제 저장에서도 서버가 동일하게 검증한다. 금칙어 목록은 BE `policy/nickname-blocked-terms.txt`로 관리한다. 모든 우회 표현을 판별하는 AI 필터가 아니라 목록 기반 정책이며 필요 시 팀 기준으로 목록을 확장한다.

프로필 사진은 선택이고 기본 아바타로 진행할 수 있다. 사진은 1MB 이하 PNG/JPEG만 허용하며 서버에서 실제 내용·치수를 검증하고 512px 이하 PNG로 재인코딩해 저장한다. 최초 프로필 저장 후 신체정보를 등록하거나 나중에 입력할 수 있다. 마이페이지와 피팅룸에서도 신체정보를 등록·수정한다.

신체정보는 본인 인증으로 `GET/PUT /api/users/me/body-profile`을 사용한다. 기본 모델(남성/여성), 키·몸무게·가슴·허리·엉덩이·허벅지 둘레를 숫자 입력 또는 슬라이더로 조절한다. 키는 cm, 몸무게는 kg, 둘레는 인치(in)로 입력하며 저장은 정수 mm와 kg이다. 인심은 화면과 미리보기에서 제외하며 서버의 기존 값은 유지한다. 피팅룸의 성별 선택은 신체정보가 등록된 경우 계정에 저장되며 재진입 시 복원된다. 미등록 상태에서는 기본 모델을 미리 볼 수 있다.

신체정보 입력 화면에서 기본 모델을 미리 보고 `저장하고 피팅룸 보기`로 이동한다. 저장 실패 시 입력 화면에서 다시 저장할 수 있다. 3D 로딩 실패·시간 초과 시 대체 이미지와 `모델 다시 불러오기` 버튼을 제공한다. 저장되는 것은 계정별 모델 선택과 치수이며 남녀 기본 GLB는 공유 에셋으로 불러온다.

웹 3D 미리보기와 피팅룸은 선택한 성별의 기본 모델에 입력·저장한 키를 반영한다. glTF의 미터 단위와 원래 모델 높이를 기준으로 전체 모델을 같은 비율로 확대·축소하고 발을 바닥에 맞춘다. 키 변경 시 모델 파일을 다시 다운로드하지 않으며 치수는 URL이나 로그에 넣지 않는다. 카메라는 같은 거리를 유지해 키 차이를 보여주며, 모델 높이가 카메라 기준 범위를 넘으면 전체가 보이도록 화면을 다시 맞춘다. 웹 이외 플랫폼은 대체 이미지를 표시한다.

몸무게는 남녀 기본형을 공통 70kg 기준으로 두고 미리보기와 피팅룸에 반영한다. 키는 유지하고 폭·깊이에 각각 `√(kg / 70)` 배율을 적용한다. 렌더링 배율에만 0.75–1.30 한계를 적용하며 이전 입력값의 배율은 누적되지 않는다. 실제 체형이나 둘레 실측을 추정하지 않으며 몸무게·키는 모델 URL이나 로그에 넣지 않는다.

로컬 Shape Key 세트가 있으면 가슴·허리·엉덩이·허벅지 둘레도 반영한다. 70kg은 모델의 Weight 키가 0인 지점이다. 허리와 엉덩이처럼 다른 키에서도 변하는 치수는 치수표의 변화량을 함께 계산한다. 모델 지원 범위 밖의 치수는 렌더링만 제한하며 저장값은 그대로 유지한다. 여성 모델에서는 선택 밑가슴둘레와 가슴둘레 차이로 [참고 컵 A–F](https://www.wacoal.jp/advice/contents/post-15.html)를 표시한다. 컵을 고르면 가슴둘레를 갱신하고 모델의 Chest 키로 보여준다. 서버 생성 요청은 기존 정책대로 PENDING을 유지한다.

권한이 있는 원본으로 로컬 Shape Key 세트를 만들 때는 Blender 4.5 이상에서 아래처럼 실행한다. 원본 파일과 결과 `web/viewer/local-morphs/`는 Git에 추가하지 않는다.

```powershell
blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python scripts/export-avatar-morphs.py -- --male <남성.blend> --female <여성.blend> --measurements <치수표.csv>
```

`scripts/run-web.ps1`과 `scripts/run-web.sh`은 결과 세 파일이 있으면 로컬 Shape Key 세트를 켠다. 직접 실행할 때는 `--dart-define=OSEE_LOCAL_AVATAR_MORPHS=true`를 추가한다. Flutter 웹 빌드는 `web/`의 로컬 파일도 복사하므로, 원본 공개 권한이 없는 로컬 작업 환경에서 만든 빌드를 배포하지 않는다. 계산 검증은 `node --test test/avatar_height_test.mjs test/avatar_weight_test.mjs test/avatar_morphs_test.mjs`로 실행한다.

마이페이지에서 프로필을 수정할 수 있고 닉네임 변경 기간 제한은 없다. 헤더 프로필 아이콘에 마우스를 올리거나 키보드 포커스를 주면 간이정보가 표시되며 클릭으로 마이페이지에 접근한다.

BE API: `POST /api/auth/web/google`, `POST /api/auth/web/session`, `POST /api/auth/web/logout`, `GET/PUT /api/users/me`. 프로필 PUT은 multipart이며 nickname, 선택 image, 선택 removeImage 필드를 사용한다. 쿠키 API는 정확한 Origin 헤더가 필요하다. 로컬에서는 localhost를 일관되게 사용한다. 배포 시 HTTPS와 `AUTH_COOKIE_SECURE=true`, 정확한 CORS 원본 설정이 필요하다. 프로필 테이블은 신규 Flyway 마이그레이션으로 생성된다.

기존 옷장·착장 화면은 로컬 데모 상태를 사용한다. 인증 게이트 추가가 사용자별 서버 데이터 연동 완료를 의미하지 않는다.

검증:

```powershell
flutter analyze
flutter test
flutter build web --dart-define-from-file=.env
```

웹 Google 로그인은 공식 [Google Identity Services JavaScript API](https://developers.google.com/identity/gsi/web/reference/js-reference)를 Dart JS interop으로 호출한다. SDK를 한 번 초기화하고 버튼과 탈퇴 연결 해제에서 공유한다. `use_fedcm_for_button=true`로 지원 Chrome에서 브라우저 중재 방식의 로그인 버튼을 사용하며 `auto_select`와 `button_auto_select`는 꺼 두어 계정 선택 없이 자동 로그인하지 않는다. 브라우저 미지원·사용자 설정에 따라 기존 팝업으로 대체될 수 있으므로 외부 SDK 경고 제거를 모든 환경에서 보장하지 않는다. ID Token 검증과 서비스 세션 발급은 기존 BE API에서 수행한다.

최초 가입 및 탈퇴 후 재가입의 프로필 입력 화면은 가입 진행 단계로 표시한다. 이 단계에서는 완료된 계정 메뉴나 로그아웃 문구를 노출하지 않고 `나가기`로 현재 인증 세션을 종료하고 공개 홈으로 돌아갈 수 있다. 소셜 인증 세션은 본인 프로필 저장에 필요하며 프로필 입력 완료를 대신하지 않는다.

A new Flutter project.

## 카카오 웹 로그인

- 백엔드의 로컬 `.env`에 `KAKAO_OAUTH_REST_API_KEY`, `KAKAO_OAUTH_CLIENT_SECRET`을 설정한다. 프론트에 키를 복사하지 않는다.
- 카카오 로그인 활성화 후 Redirect URI를 `http://localhost:8080/api/auth/social/kakao/callback`으로 등록한다.
- 프론트는 `.env`의 `OSEE_API_BASE_URL`로 팝업을 연다. 기본 주소는 `http://localhost:8080`이다.
- 배포에서는 백엔드 `OSEE_FRONTEND_ORIGIN`을 정확한 프론트 원본으로 지정하고 HTTPS를 사용한다. localhost와 127.0.0.1을 혼용하지 않는다.
- 카카오로 계속하기 → 카카오 인증 팝업 → 서버 검증 → 홈 순서다. 팝업 차단 시 브라우저에서 허용한다.
- state는 브라우저에 바인딩된 5분 일회성 값이며 서버 재시작 시 무효화된다. 다중 서버 배포 전에는 공유 저장소로 전환해야 한다.
- 카카오 callback도 동일한 HttpOnly 세션 쿠키를 설정한다. 이후 세션 복원·프로필 입력·마이페이지는 Google과 같은 흐름을 사용한다.

공식 REST 흐름: [카카오 로그인 REST API](https://developers.kakao.com/docs/ko/kakaologin/rest-api)

## 회원탈퇴 및 여러 탭의 세션

마이페이지의 회원탈퇴 버튼은 복구 불가 안내와 확인창을 제공한다. 취소하면 API를 호출하지 않는다. 내부 탈퇴를 먼저 확정한 뒤 브라우저의 공식 Google SDK revoke로 연결을 자동 해제한다. 진행/성공/실패를 구분하고 실패 시에만 수동 해제 링크를 제공한다. 제공자 식별값은 메모리에서만 잠시 사용하며 완료 후 제거한다. Kakao 자동 해제에는 BE 전용 `KAKAO_ADMIN_KEY`가 필요하며 프론트 설정에 넣지 않는다. 자세한 후속 작업 상태와 새 Flyway는 BE README를 확인한다.

동일 원본 여러 탭의 쿠키 회전/로그아웃/탈퇴 요청은 Web Locks로 직렬화한다. 지원되지 않는 브라우저는 일반 요청으로 동작하며, 서버의 오래된 응답도 새 쿠키를 삭제하지 않는다. BroadcastChannel로 다른 탭에도 종료 상태를 전달한다. 토큰/신체정보를 채널이나 localStorage에 보내지 않는다.

Google SDK의 `The given origin is not allowed for the given client ID`는 앱 예외를 숨겨 해결하지 않는다. 현재 실행하는 Web Client ID의 승인된 JavaScript 원본에 `http://localhost`와 `http://localhost:5173`이 모두 있는지 확인한다. BE/FE ID를 바꿨다면 두 서버를 재시작한다. [Google 공식 설정](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 상품 목록 API 연동

- CLOTHES는 인증 후 `GET /api/garments`를 조회한다. 백엔드는 Garment 기본 조회 기능과 `V2611041300` 마이그레이션이 적용된 버전을 실행해야 한다.
- 선택한 대분류 또는 하위 카테고리를 `categoryCode`로 전달한다. All은 코드를 생략한다. 기본 최신 등록순(`sort=LATEST`), 한 페이지 20개이며 이전/다음 페이지로 이동한다.
- 로딩, 빈 목록, 안전한 오류 메시지와 재시도, 로그인 경로, 이미지 실패 대체 표시를 제공한다. 카테고리를 바꾸면 첫 페이지로 이동하고, 로그아웃하거나 응답 순서가 뒤바뀐 경우 이전 데이터를 표시하지 않는다.
- 카드에는 서버가 제공한 상품명·카테고리명·대표 이미지만 표시한다. 브랜드는 1차 범위에서 제외한다. + 담기와 피팅룸 상세·옵션·소재·실측을 서버 API로 연결하며 3D 모델은 미제공 상태를 표시한다.
- CLOTHES 목록은 기존 샘플 의류를 사용하지 않는다. 기존 피팅룸·옷장·착장 데모 상태는 별도다. 현재 로컬 DB에 상품이 없으면 빈 목록이 정상이다.
- 검증: `flutter test`, `flutter analyze`, `flutter build web --dart-define-from-file=.env`.

## 서버 상품 담기와 피팅룸

- CLOTHES 카드의 + 버튼은 서버 상품 ID로 의류를 담고, 다시 누르면 취소한다. 별도 상품 상세 페이지로 이동하지 않는다.
- 피팅룸에서 담은 의류를 선택하면 공통 상세와 `/api/garments/{id}/options`를 조회한다. 색상을 바꾸면 사이즈 선택을 초기화하고, 사용 가능한 사이즈만 선택할 수 있다.
- 사이즈 선택은 `/api/garments/{id}/selection`을 호출해 실측·검증 오류를 조회한다. 길이는 화면에서만 mm→cm로 변환하고 단면·둘레·길이를 구분해 표시한다. 측정 출처·측정일·측정 방법을 표시한다.
- 소재·혼용률 미확인, 실측 없음, 카테고리 측정 항목 미설정, 허용 범위 미설정과 3D 모델 미제공을 명시한다. 실측은 조회 전용이고 임의 편집/추정하지 않는다.
- 담기와 옵션 선택은 현재 로그인 세션의 메모리 상태다. 새로고침 시 초기화하고 로그아웃 시 제거한다. 옷장·착장 서버 저장을 대신하지 않는다. 기존 옷장·착장은 로컬 데모이며 서버 상품 연결은 별도 작업이다.
- 중앙 아바타는 예시 이미지이며 실제 의류 착용 결과가 아니다. 3D 모델 계약 확정 전 렌더링이나 핏 판정을 수행하지 않는다.
- 백엔드 `V2611171200`, `V2611171210` 마이그레이션 및 옵션 API가 필요하다.
