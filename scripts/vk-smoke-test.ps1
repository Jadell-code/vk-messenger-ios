param(
    [string]$AccessToken,
    [string]$ClientId,
    [int]$Count = 5
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $root 'Config\Local.xcconfig'
$apiVersion = '5.199'

function Read-ClientId {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $line = Get-Content -LiteralPath $Path |
        Where-Object { $_ -match '^\s*VK_CLIENT_ID\s*=' } |
        Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split '=', 2)[1].Trim()
}

function Invoke-VK {
    param(
        [string]$Method,
        [hashtable]$Params
    )

    $body = @{
        access_token = $AccessToken
        v = $apiVersion
        lang = 'ru'
    }
    foreach ($key in $Params.Keys) {
        $body[$key] = $Params[$key]
    }

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.vk.com/method/$Method" `
            -Method Post `
            -Body $body `
            -TimeoutSec 30
    } catch {
        return [pscustomobject]@{ Error = "HTTP error: $($_.Exception.Message)" }
    }

    if ($response.error) {
        return [pscustomobject]@{
            Error = "VK API $($response.error.error_code): $($response.error.error_msg)"
        }
    }

    return [pscustomobject]@{ Response = $response.response }
}

if (-not $ClientId) {
    $ClientId = Read-ClientId -Path $configPath
}

if (-not $AccessToken) {
    $AccessToken = $env:VK_TOKEN
}

if (-not $AccessToken) {
    $secure = Read-Host 'Paste VK access_token (input is hidden)' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $AccessToken = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

if (-not $AccessToken) {
    throw 'No access token provided.'
}

Write-Host ''
Write-Host 'VK API smoke test' -ForegroundColor Cyan
Write-Host '-----------------' -ForegroundColor Cyan

Write-Host '1. users.get...' -ForegroundColor Cyan
$me = Invoke-VK -Method 'users.get' -Params @{
    fields = 'photo_100,online,status'
}
if ($me.Error) {
    Write-Host "   FAIL: $($me.Error)" -ForegroundColor Red
    exit 1
}
$user = $me.Response[0]
Write-Host "   OK: id=$($user.id), name=$($user.first_name) $($user.last_name)" -ForegroundColor Green

Write-Host '2. messages.getConversations...' -ForegroundColor Cyan
$conversations = Invoke-VK -Method 'messages.getConversations' -Params @{
    count = "$Count"
    extended = '1'
    fields = 'photo_100,photo_200,online,status'
}
if ($conversations.Error) {
    Write-Host "   FAIL: $($conversations.Error)" -ForegroundColor Red
    Write-Host '   This usually means the VK app has no access to messages.*.' -ForegroundColor Yellow
    exit 1
}

$conv = $conversations.Response
Write-Host "   OK: conversations=$($conv.count), returned=$($conv.items.Count)" -ForegroundColor Green
foreach ($item in ($conv.items | Select-Object -First $Count)) {
    $peer = $item.conversation.peer
    $title = $null

    if ($peer.type -eq 'user') {
        $profile = $conv.profiles | Where-Object { $_.id -eq $peer.id } | Select-Object -First 1
        if ($profile) { $title = "$($profile.first_name) $($profile.last_name)" }
    } elseif ($peer.type -eq 'chat') {
        $title = $item.conversation.chat_settings.title
    } elseif ($peer.type -eq 'group') {
        $group = $conv.groups | Where-Object { $_.id -eq $peer.id } | Select-Object -First 1
        if ($group) { $title = $group.name }
    }

    if (-not $title) { $title = "peer $($peer.id)" }
    $unread = $item.conversation.unread_count
    Write-Host "   - $title (peer_id=$($peer.id), unread=$unread)"
}

Write-Host '3. messages.getLongPollServer...' -ForegroundColor Cyan
$lp = Invoke-VK -Method 'messages.getLongPollServer' -Params @{
    lp_version = '3'
    need_pts = '0'
}
if ($lp.Error) {
    Write-Host "   FAIL: $($lp.Error)" -ForegroundColor Red
    Write-Host '   LongPoll is not available for this VK app.' -ForegroundColor Yellow
    exit 1
}
Write-Host "   OK: server=$($lp.Response.server), ts=$($lp.Response.ts)" -ForegroundColor Green

Write-Host ''
Write-Host 'VK API smoke test passed.' -ForegroundColor Green
Write-Host 'The token was not printed. Revoke it in VK settings after testing if needed.' -ForegroundColor Yellow
