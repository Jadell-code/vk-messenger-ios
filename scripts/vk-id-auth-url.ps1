param(
    [string]$ClientId = '54882991',
    [string]$Scope = 'vkid.personal_info',
    [switch]$Open
)

$ErrorActionPreference = 'Stop'

$statePath = Join-Path $env:TEMP 'vk-id-pkce.json'

function New-Base64Url([byte[]]$Bytes) {
    return [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

$verifierBytes = New-Object byte[] 64
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($verifierBytes)
$verifier = New-Base64Url $verifierBytes

$sha = [Security.Cryptography.SHA256]::Create()
$challenge = New-Base64Url $sha.ComputeHash([Text.Encoding]::ASCII.GetBytes($verifier))

$stateBytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($stateBytes)
$state = New-Base64Url $stateBytes

$redirect = 'http://localhost'

$url = 'https://id.vk.ru/authorize' +
    '?response_type=code' +
    '&client_id=' + [uri]::EscapeDataString($ClientId) +
    '&redirect_uri=' + [uri]::EscapeDataString($redirect) +
    '&state=' + [uri]::EscapeDataString($state) +
    '&code_challenge=' + [uri]::EscapeDataString($challenge) +
    '&code_challenge_method=S256' +
    '&scope=' + [uri]::EscapeDataString($Scope) +
    '&prompt=consent'

@{
    client_id = $ClientId
    redirect_uri = $redirect
    code_verifier = $verifier
    state = $state
} | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8

Write-Host ''
Write-Host 'Open this URL and approve access:' -ForegroundColor Cyan
Write-Host $url
Write-Host ''
Write-Host 'After approval the browser goes to:' -ForegroundColor Cyan
Write-Host 'http://localhost/?code=...&state=...&device_id=...'
Write-Host ''
Write-Host 'Then run:' -ForegroundColor Yellow
Write-Host '  .\scripts\vk-id-exchange.ps1 -RedirectUrl "<full URL from address bar>"'
Write-Host ''

if ($Open) {
    Start-Process $url
}
