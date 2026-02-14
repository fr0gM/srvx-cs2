param (
    [string]$ServerPath='E:\CS2\server'
)

$ErrorActionPreference = "Stop"

$MetamodDownloadUrl = "https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1384-windows.zip"
$CounterStrikeSharpDownloadUrl = "https://github.com/roflmuffin/CounterStrikeSharp/releases/download/v1.0.362/counterstrikesharp-with-runtime-windows-1.0.362.zip"
$MatchZyDownloadUrl = "https://github.com/shobhit-pathak/MatchZy/releases/download/0.8.15/MatchZy-0.8.15.zip"

Write-Host "Checking directories..." -ForegroundColor Cyan
$CSGOPath = Join-Path $ServerPath "game\csgo" 
$CSGOAddonsPath = Join-Path $CSGOPath "addons"
$GameInfoPath = Join-Path $CSGOPath "gameinfo.gi"

Write-Host "Installing Metamod" -ForegroundColor Cyan
if((Test-Path $CSGOAddonsPath\metamod)) {
    Write-Host "Metamod already exists. Skipping download and installation." -ForegroundColor Yellow
}
else {
    Invoke-WebRequest $MetamodDownloadUrl -OutFile E:\CS2\resources\metamod.zip
    Expand-Archive -Path E:\CS2\resources\metamod.zip -DestinationPath $CSGOPath -Force 
    Write-Host "Metamod Installed" -ForegroundColor Green
}

Write-Host "Activating Metamod in gameinfo.gi..." -ForegroundColor Cyan
$FileLines = Get-Content $GameInfoPath
# Check if already installed
$AlreadyInstalled = $FileLines | Select-String "csgo/addons/metamod" -SimpleMatch
if ($AlreadyInstalled) {
    Write-Host "Metamod already present in gameinfo.gi." -ForegroundColor Yellow
}
else {
    $NewContent = @()
    $InsideSearchPaths = $false
    $Inserted = $false
    
    foreach ($Line in $FileLines) {
        # Add the current line to our new list
        $NewContent += $Line

        # Detect the start of the SearchPaths block
        if ($Line -match "SearchPaths") {
            $InsideSearchPaths = $true
        }

        # If we are inside SearchPaths, look for the opening bracket '{'
        # We insert our line immediately after the bracket.
        if ($InsideSearchPaths -and -not $Inserted -and $Line -match "\{") {
            # Add the Metamod line with proper indentation
            $NewContent += "			Game	csgo/addons/metamod"
            $Inserted = $true
            Write-Host "Inserted Metamod line at top of SearchPaths." -ForegroundColor Green
        }
    }

    # Save the clean array back to the file
    Set-Content -Path $GameInfoPath -Value $NewContent
    Write-Host "gameinfo.gi updated successfully." -ForegroundColor Green
}

Write-Host "Installing CounterStrikeSharp Runtime" -ForegroundColor Cyan
if(Test-Path $CSGOAddonsPath\cs2sharp) {
    Write-Host "CounterStrikeSharp Runtime already exists. Skipping download and installation." -ForegroundColor Yellow
}
else {
    Invoke-WebRequest $CounterStrikeSharpDownloadUrl -OutFile E:\CS2\resources\cs2sharp-runtime.zip
    Expand-Archive -Path E:\CS2\resources\cs2sharp-runtime.zip -DestinationPath $CSGOPath  -Force
    Write-Host "CounterStrikeSharp Runtime Installed" -ForegroundColor Green
}

Write-Host "Installing MatchZy" -ForegroundColor Cyan
if(Test-Path $CSGOAddonsPath\MatchZy) {
    Write-Host "MatchZy already exists. Skipping download and installation." -ForegroundColor Yellow
}
else {
    Invoke-WebRequest $MatchZyDownloadUrl -OutFile E:\CS2\resources\MatchZy.zip
    Expand-Archive -Path E:\CS2\resources\MatchZy.zip -DestinationPath $CSGOPath -Force
    Write-Host "MatchZy Installed" -ForegroundColor Green
}

Write-Host "Copy Server.cfg" -ForegroundColor Cyan
Copy-Item -Path "E:\CS2\resources\server.cfg" -Destination "$CSGOPath\cfg\server.cfg" -Force
Write-Host "Server.cfg copied successfully." -ForegroundColor Green

Write-Host "Copy admins.json" -ForegroundColor Cyan
Copy-Item -Path "E:\CS2\resources\admins.json" -Destination "$CSGOPath\addons\counterstrikesharp\configs\admins.json" -Force
Write-Host "admins.json copied successfully." -ForegroundColor Green
