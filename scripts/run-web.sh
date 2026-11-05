#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ -f .env ]]; then
  config_file=.env
elif [[ -f .env.json ]]; then
  config_file=.env.json
else
  echo "환경설정 파일이 없습니다. .env.example을 .env로 복사하고 Google Client ID를 설정하세요." >&2
  exit 1
fi

echo "서버 준비가 끝나면 브라우저에서 http://localhost:5173 을 열어주세요."
exec flutter run -d web-server --web-hostname localhost --web-port 5173 --dart-define-from-file="$config_file" "$@"
