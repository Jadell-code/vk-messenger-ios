param(
    [string]$ClientId,
    [switch]$Open
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $root 'Config\Local.xcconfig'

function Read-ClientId {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $line = Get-Content -LiteralPath $Path |
        Where-Object { $_ -match '^\s*VK_CLIENT_ID\s*=' } |
        Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split '=', 2)[1].Trim()
}

if (-not $ClientId) {
    $ClientId = Read-ClientId -Path $configPath
}

if (-not $ClientId -or $ClientId -eq '0' -or $ClientId -notmatch '^\d+$') {
    throw "Invalid VK_CLIENT_ID: '$ClientId'. Set a numeric client_id in Config\Local.xcconfig."
}

$redirect = 'https://oauth.vk.com/blank.html'
$scope = 'messages,offline,photos,wall,groups,email'
$url = 'https://oauth.vk.com/authorize' +
    '?client_id=' + [uri]::EscapeDataString($ClientId) +
    '&display=page' +
    '&redirect_uri=' + [uri]::EscapeDataString($redirect) +
    '&scope=' + [uri]::EscapeDataString($scope) +
    '&response_type=token' +
    '&v=5.199' +
    '&revoke=1'

Write-Host ''
Write-Host 'Open this URL in your browser:' -ForegroundColor Cyan
Write-Host $url
Write-Host ''
Write-Host 'After login VK redirects to:' -ForegroundColor Cyan
Write-Host 'https://oauth.vk.com/blank.html#access_token=...&expires_in=...&user_id=...'
Write-Host ''
Write-Host 'Copy only the access_token value. Do not share it with anyone.' -ForegroundColor Yellow
Write-Host 'Then run: .\scripts\vk-smoke-test.ps1'
Write-Host ''

if ($Open) {
    Start-Process $url
}
