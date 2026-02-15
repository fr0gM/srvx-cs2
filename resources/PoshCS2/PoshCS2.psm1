function Install-PoshCS2-ServerResources {
    param (
        [string]$ServerPath = 'E:\CS2\server',
        [switch]$Force
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
    if (((Test-Path $CSGOAddonsPath\metamod) -and !$Force)) {
        # If force is not enabled and metamod exists, skip download and installation
        Write-Host "Metamod already exists. Skipping download and installation." -ForegroundColor Yellow
    }
    else {
        # Download and install metamod
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
    if ((Test-Path $CSGOAddonsPath\counterstrikesharp) -and !$Force) {
        # If force is not enabled and counterstrikesharp exists, skip download and installation
        Write-Host "CounterStrikeSharp Runtime already exists. Skipping download and installation." -ForegroundColor Yellow
    }
    else {
        # Download and install counterstrikesharp
        Invoke-WebRequest $CounterStrikeSharpDownloadUrl -OutFile E:\CS2\resources\cs2sharp-runtime.zip
        Expand-Archive -Path E:\CS2\resources\cs2sharp-runtime.zip -DestinationPath $CSGOPath  -Force
        Write-Host "CounterStrikeSharp Runtime Installed" -ForegroundColor Green
    }

    Write-Host "Installing MatchZy" -ForegroundColor Cyan
    if ((Test-Path $CSGOAddonsPath\counterstrikesharp\plugins\MatchZy) -and !$Force) {
        # If force is not enabled and MatchZy exists, skip download and installation
        Write-Host "MatchZy already exists. Skipping download and installation." -ForegroundColor Yellow
    }
    else {
        # Download and install MatchZy
        Invoke-WebRequest $MatchZyDownloadUrl -OutFile E:\CS2\resources\MatchZy.zip
        Expand-Archive -Path E:\CS2\resources\MatchZy.zip -DestinationPath $CSGOPath -Force
        Write-Host "MatchZy Installed" -ForegroundColor Green
    }

    Write-Host "Copy Server.cfg to path: $("$CSGOPath\cfg\")" -ForegroundColor Cyan
    Copy-Item -Path "E:\CS2\resources\server.cfg" -Destination "$CSGOPath\cfg\" -Force -Verbose
    Write-Host "Server.cfg copied successfully." -ForegroundColor Green

    Write-Host "Copy config.cfg to path: $("$CSGOPath\cfg\MatchZy\")" -ForegroundColor Cyan
    Copy-Item -Path "E:\CS2\resources\config.cfg" -Destination "$CSGOPath\cfg\MatchZy\" -Force -Verbose
    Write-Host "config.cfg copied successfully." -ForegroundColor Green
 
    Write-Host "Copy secrets.cfg to path: $("$CSGOPath\cfg\")" -ForegroundColor Cyan
    Copy-Item -Path "E:\CS2\resources\secrets.cfg" -Destination "$CSGOPath\cfg\" -Force -Verbose
    Write-Host "secrets.cfg copied successfully." -ForegroundColor Green

    Write-Host "Copy admins.json to path: $("$CSGOPath\addons\counterstrikesharp\configs\")" -ForegroundColor Cyan
    Copy-Item -Path "E:\CS2\resources\admins.json" -Destination "$CSGOPath\addons\counterstrikesharp\configs\" -Force -Verbose
    Write-Host "admins.json copied successfully." -ForegroundColor Green

}
function Update-PoshCS2-Server {
    param (
        [string]$SteamCMDPath = "E:\CS2\steamcmd\steamcmd.exe"
    )
    & $SteamCMDPath +runscript cs2-updater.txt
}

function Start-PoshCS2-Server {
    param (          
        $ServerPath = "E:\CS2\server\game\bin\win64\cs2.exe",
        $Port = 27015,
        $TVPort = 27020,
        $Map = "de_mirage",
        $LogFile = 1,
        $MaxPlayers = 16
    )
    & $ServerPath -dedicated -usercon -console -port $Port +tv_port $TVPort +map $Map +sv_logfile $LogFile -maxplayers $MaxPlayers
}
function Stop-PoshCS2-Server {
    $Processes = Get-CimInstance Win32_Process -Filter "Name LIKE 'cs2%'"
    foreach ($Process in $Processes) {
        if ($Process.CommandLine -like "*-dedicated*") {
            Stop-Process -Id $Process.ProcessId -Force
            Write-Host "Stopped CS2 Dedicated Server (PID: $($Process.ProcessId))" -ForegroundColor Yellow
        }
    }
}
function Restart-PoshCS2-Server {
    Stop-PoshCS2-Server
    Start-PoshCS2-Server
}

function Send-PoshCS2-Command {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("matchzy_loadmatch", "matchzy_listbackups", "matchzy_loadbackup", "css_start", "css_forcepause", "css_forceunpause", "css_endmatch", 'css_asay', 'mp_terminate_match')]
        [string]$Command,
        [string]$Argument = $null
    )

    $CommandsRequiringArgument = @(
        'matchzy_loadmatch',
        'matchzy_loadbackup',
        'mp_terminate_match',
        'say'
    )

    if ($Command -in $CommandsRequiringArgument -and [string]::IsNullOrWhiteSpace($Argument)) {
        Throw "The command '$Command' requires an argument."
    }

    $ConfFile = Get-content E:\cs2\resources\rcon.json | ConvertFrom-Json

    # Point this to where you saved rcon.exe
    $RconPath = "E:\CS2\resources\rcon.exe"

    & $RconPath -a $ConfFile.default.address -p $ConfFile.default.password "$Command $Argument"
}                                         

function Load-PoshCS2-Match {
    param (
        [Parameter(Mandatory = $true)]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                Get-ChildItem "E:\CS2\server\game\csgo\*.json" | Select-Object -ExpandProperty Name
            })
        ] 
        [string]$MatchFile,
        [switch]$Force
    )
    Send-PoshCS2-Command -Command "matchzy_loadmatch" -Argument $MatchFile

    if ($Force) {
        Send-PoshCS2-Command -Command "css_start"
    }
}

function Start-PoshCS2-Match {
    Send-PoshCS2-Command -Command "css_start"
}

function Stop-PoshCS2-Match {
    param (
        [switch]$Confirm
    )
    Send-PoshCS2-Command -Command "css_endmatch"
}
#FIX ME
function Pause-PoshCS2-Match {
    Send-PoshCS2-Command -Command "css_forcepause"
}
#FIX ME
function Unpause-PoshCS2-Match {
    Send-PoshCS2-Command -Command "css_forceunpause"
}

function Get-PoshCS2-RoundBackups {
    return (Get-ChildItem "E:\CS2\server\game\csgo\MatchZyDataBackup\*" | Select-Object -ExpandProperty Name)
}

function Restore-PoshCS2-Round {
    param (
        [Parameter(Mandatory = $true)]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                Get-ChildItem "E:\CS2\server\game\csgo\MatchZyDataBackup\*" | Select-Object -ExpandProperty Name
            })
        ] 
        [string]$BackupFile
    )
    Send-PoshCS2-Command -Command "matchzy_loadbackup" -Argument $BackupFile
}
function Send-Posh2CS-Message {
    param(
        [String]
        $Message
    )
    Send-PoshCS2-Command -Command "css_asay" -Argument $Message
}
Export-ModuleMember -Function *
