param(
    [Parameter(Mandatory = $true)]
    [string]$RedirectUrl,
    [string]$ClientId = '54882991'
)

$ErrorActionPreference = 'Stop'

$statePath = Join-Path $env:TEMP 'vk-id-pkce.json'
if (-not (Test-Path -LiteralPath $statePath)) {
    throw 'PKCE state not found. Run .\scripts\vk-id-auth-url.ps1 first.'
}

$pkce = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json

$uri = [uri]$RedirectUrl
$query = @{}
foreach ($pair in ($uri.Query.TrimStart('?') -split '&')) {
    if (-not $pair) { continue }
    $kv = $pair -split '=', 2
    $query[[uri]::UnescapeDataString($kv[0])] = [uri]::UnescapeDataString(($kv[1] -replace '\+', ' '))
}

if ($query.error) {
    throw "VK ID returned error: $($query.error) - $($query.error_description)"
}
if (-not $query.code) {
    throw 'No code in redirect URL.'
}
if ($query.state -ne $pkce.state) {
    throw 'State mismatch. The redirect URL does not belong to the last auth request.'
}

$body = @{
    grant_type = 'authorization_code'
    code_verifier = $pkce.code_verifier
    redirect_uri = $pkce.redirect_uri
    code = $query.code
    client_id = $ClientId
    device_id = $query.device_id
    state = $query.state
}

Write-Host ''
Write-Host 'VK ID token exchange' -ForegroundColor Cyan
Write-Host '--------------------' -ForegroundColor Cyan

try {
    $tokens = Invoke-RestMethod -Uri 'https://id.vk.ru/oauth2/auth' -Method Post -Body $body -TimeoutSec 30
} catch {
    $details = $_.ErrorDetails.Message
    throw "Token exchange failed: $($_.Exception.Message) $details"
}

Write-Host "OK: user_id=$($tokens.user_id), scope=$($tokens.scope), expires_in=$($tokens.expires_in)" -ForegroundColor Green
Write-Host 'Tokens received (values are hidden).' -ForegroundColor Yellow

$accessToken = $tokens.access_token
if (-not $accessToken) { throw 'No access_token in response.' }

Write-Host ''
Write-Host '1. VK ID user_info...' -ForegroundColor Cyan
try {
    $user = Invoke-RestMethod -Uri 'https://id.vk.ru/oauth2/user_info' -Method Post -Body @{
        client_id = $ClientId
        access_token = $accessToken
    } -TimeoutSec 30
    Write-Host "   OK: $($user.user.first_name) $($user.user.last_name), id=$($user.user.user_id)" -ForegroundColor Green
} catch {
    Write-Host "   FAIL: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host '2. VK API users.get with VK ID token...' -ForegroundColor Cyan
try {
    $vkUser = Invoke-RestMethod -Uri 'https://api.vk.com/method/users.get' -Method Post -Body @{
        access_token = $accessToken
        v = '5.199'
        fields = 'photo_100,online,status'
    } -TimeoutSec 30
    if ($vkUser.error) {
        Write-Host "   FAIL: VK API $($vkUser.error.error_code): $($vkUser.error.error_msg)" -ForegroundColor Red
    } else {
        Write-Host "   OK: id=$($vkUser.response[0].id)" -ForegroundColor Green
    }
} catch {
    Write-Host "   FAIL: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host '3. VK API messages.getConversations with VK ID token...' -ForegroundColor Cyan
try {
    $conversations = Invoke-RestMethod -Uri 'https://api.vk.com/method/messages.getConversations' -Method Post -Body @{
        access_token = $accessToken
        v = '5.199'
        count = '5'
    } -TimeoutSec 30
    if ($conversations.error) {
        Write-Host "   FAIL: VK API $($conversations.error.error_code): $($conversations.error.error_msg)" -ForegroundColor Red
    } else {
        Write-Host "   OK: conversations=$($conversations.response.count)" -ForegroundColor Green
    }
} catch {
    Write-Host "   FAIL: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host '4. VK ID refresh token...' -ForegroundColor Cyan
try {
    $refreshed = Invoke-RestMethod -Uri 'https://id.vk.ru/oauth2/auth' -Method Post -Body @{
        grant_type = 'refresh_token'
        refresh_token = $tokens.refresh_token
        client_id = $ClientId
        device_id = $query.device_id
        state = $query.state
    } -TimeoutSec 30
    $rotated = if ($refreshed.refresh_token) { 'yes' } else { 'no' }
    Write-Host "   OK: expires_in=$($refreshed.expires_in), refresh token rotated=$rotated" -ForegroundColor Green
} catch {
    $details = $_.ErrorDetails.Message
    Write-Host "   FAIL: $($_.Exception.Message) $details" -ForegroundColor Red
}

Remove-Item -LiteralPath $statePath -Force
Write-Host ''
Write-Host 'Done. The access token was not printed.' -ForegroundColor Yellow
