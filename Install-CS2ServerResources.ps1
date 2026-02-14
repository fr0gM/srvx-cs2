param (
    [string]$ServerPath='E:\CS2\server\steamapps\downloading\730'
)

$ErrorActionPreference = "Stop"

$MetamodDownloadUrl = "https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1387-windows.zip"
$CounterStrikeSharpDownloadUrl = "https://github.com/roflmuffin/CounterStrikeSharp/releases/download/v1.0.362/counterstrikesharp-with-runtime-windows-1.0.362.zip"
$MatchZyDownloadUrl = "https://github.com/shobhit-pathak/MatchZy/releases/download/0.8.15/MatchZy-0.8.15.zip"

Write-Host "Checking directories..." -ForegroundColor Cyan
$CSGOPath = Join-Path $ServerPath "game\csgo" 
$CSGOAddonsPath = Join-Path $CSGOPath "addons"
$GameInfoPath = Join-Path $CSGOPath "gameinfo.gi"

Write-Host "Installing Metamod" -ForegroundColor Cyan
if(-Test-Path $CSGOAddonsPath\metamod) {
    Write-Host "Metamod already exists. Skipping download and installation." -ForegroundColor Yellow
}
else {
    Invoke-WebRequest $MetamodDownloadUrl -OutFile E:\CS2\resources\metamod.zip
    Expand-Archive -Path E:\CS2\resources\metamod.zip -DestinationPath $CSGOAddonsPath\metamod -Force
    Write-Host "Metamod Installed" -ForegroundColor Green
}

Write-Host "Activating Metamod in gameinfo.gi..." -ForegroundColor Cyan
$Content = Get-Content $GameInfoPath -Raw
$MetamodLine = "			Game	csgo/addons/metamod"

if ($Content -match "csgo/addons/metamod") {
    Write-Host "Metamod entry already exists in gameinfo.gi. Skipping edit." -ForegroundColor Yellow
}
else {
    $NewContent = $Content -replace '(\s+)(Game\s+csgo)', "$1$MetamodLine$1`$2"
    
    if ($NewContent -ne $Content) {
        Set-Content -Path $GameInfoPath -Value $NewContent -NoNewline
        Write-Host "Successfully updated gameinfo.gi" -ForegroundColor Green
    }
    else {
        Write-Warning "Could not automatically patch gameinfo.gi. You may need to edit it manually."
    }
}

Write-Host "Installing CounterStrikeSharp Runtime" -ForegroundColor Cyan
if(-Test-Path $CSGOAddonsPath\cs2sharp) {
    Write-Host "CounterStrikeSharp Runtime already exists. Skipping download and installation." -ForegroundColor Yellow
}
else {
    Invoke-WebRequest $CounterStrikeSharpDownloadUrl -OutFile E:\CS2\resources\cs2sharp-runtime.zip
    Expand-Archive -Path E:\CS2\resources\cs2sharp-runtime.zip -DestinationPath $CSGOAddonsPath\cs2sharp -Force
    Write-Host "CounterStrikeSharp Runtime Installed" -ForegroundColor Green
}

Write-Host "Installing MatchZy" -ForegroundColor Cyan
if(-Test-Path $CSGOAddonsPath\MatchZy) {
    Write-Host "MatchZy already exists. Skipping download and installation." -ForegroundColor Yellow
}
else {
    Invoke-WebRequest $MatchZyDownloadUrl -OutFile E:\CS2\resources\MatchZy.zip
    Expand-Archive -Path E:\CS2\resources\MatchZy.zip -DestinationPath $CSGOAddonsPath\MatchZy -Force
    Write-Host "MatchZy Installed" -ForegroundColor Green
}