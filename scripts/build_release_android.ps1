param(
    [string]$ApiBaseUrl = $env:AI_API_BASE_URL
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $ApiBaseUrl = 'https://aman-sarthi.onrender.com'
}

$parsedUrl = $null
if (-not [Uri]::TryCreate($ApiBaseUrl.Trim(), [UriKind]::Absolute, [ref]$parsedUrl) -or
    $parsedUrl.Scheme -ne 'https' -or
    [string]::IsNullOrWhiteSpace($parsedUrl.Host) -or
    $parsedUrl.UserInfo -or
    $parsedUrl.Query -or
    $parsedUrl.Fragment) {
    throw 'AI_API_BASE_URL must be a valid HTTPS backend base URL without credentials, query, or fragment.'
}

$baseUrl = $parsedUrl.AbsoluteUri.TrimEnd('/')
$readinessUrl = "$baseUrl/readyz"
try {
    $readiness = Invoke-RestMethod -Uri $readinessUrl -Method Get -TimeoutSec 30
} catch {
    throw "Backend readiness check failed at $readinessUrl. Confirm the deployed URL and server configuration. $($_.Exception.Message)"
}

if ($readiness.ready -ne $true) {
    throw "Backend at $readinessUrl is reachable but not ready. Configure GEMINI_API_KEY in the backend host's secure environment settings."
}

$smokePayload = @{
    messages = @(
        @{
            role = 'user'
            content = 'Reply with the single word READY.'
        }
    )
} | ConvertTo-Json -Depth 4

try {
    $smokeResponse = Invoke-WebRequest `
        -Uri "$baseUrl/api/chat" `
        -Method Post `
        -ContentType 'application/json' `
        -Body $smokePayload `
        -TimeoutSec 100
} catch {
    throw "Real Gemini API smoke test failed at $baseUrl/api/chat. Check the Gemini key, model access, and service logs. $($_.Exception.Message)"
}

$hasDelta = $false
$hasDone = $false
foreach ($line in ($smokeResponse.Content -split "\r?\n")) {
    if (-not $line.StartsWith('data:')) {
        continue
    }

    try {
        $event = $line.Substring(5).Trim() | ConvertFrom-Json -ErrorAction Stop
    } catch {
        continue
    }

    if ($event.type -eq 'error') {
        throw "Real Gemini API smoke test failed: $($event.message)"
    }
    if ($event.type -eq 'delta' -and -not [string]::IsNullOrWhiteSpace($event.text)) {
        $hasDelta = $true
    }
    if ($event.type -eq 'done') {
        $hasDone = $true
    }
}

if (-not $hasDelta -or -not $hasDone) {
    throw 'Real Gemini API smoke test returned no completed text response; APK build stopped.'
}

Write-Output 'Real Gemini API smoke test passed.'

& flutter build apk --release "--dart-define=AI_API_BASE_URL=$baseUrl"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$apkPath = Join-Path $PSScriptRoot '..\build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path $apkPath)) {
    throw "Flutter reported success but the expected APK was not found at $apkPath."
}

Write-Output "Release APK: $((Resolve-Path $apkPath).Path)"