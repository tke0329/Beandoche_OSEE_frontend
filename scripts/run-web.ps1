$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    if (-not (Test-Path -LiteralPath '.env.json')) {
        throw 'Copy config/development.example.json to .env.json and set GOOGLE_OAUTH_CLIENT_ID first.'
    }
    Write-Host 'Open http://localhost:5173 in your normal browser. Use the same browser profile to retain your login.'
    flutter run -d web-server --web-hostname localhost --web-port 5173 --dart-define-from-file=.env.json
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
