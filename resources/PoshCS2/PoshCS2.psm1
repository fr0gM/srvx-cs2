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
        [string]$SteamCMDPath = "E:\CS2\steamcmd\steamcmd.exe",
        [string]$ServerPath = "E:\CS2\Server",
        [string]$ComputerName = $null
    )
    if ($ComputerName) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($sp)
            & $sp +force_install_dir $ServerPath +login anonymous +app_update 730 +quit
        } -ArgumentList $SteamCMDPath
    }
    else {
        & $SteamCMDPath +force_install_dir $ServerPath +login anonymous +app_update 730 +quit

    }

    Write-Host "Update completed successfully." -ForegroundColor Green
}

function Start-PoshCS2-Server {
    param (          
        $ServerPath = "E:\CS2\server\game\bin\win64\cs2.exe",
        $Port = 27015,
        $TVPort = 27020,
        $Map = "de_mirage",
        $LogFile = 1,
        $MaxPlayers = 16,
        [string]$ComputerName = $null
    )
    if ($ComputerName) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($sp, $p, $tvp, $m, $lf, $mp)
            & $sp -dedicated -usercon -console -port $p +tv_port $tvp +map $m +sv_logfile $lf -maxplayers $mp
        } -ArgumentList $ServerPath, $Port, $TVPort, $Map, $LogFile, $MaxPlayers
    }
    else {
        & $ServerPath -dedicated -usercon -console -port $Port +tv_port $TVPort +map $Map +sv_logfile $LogFile -maxplayers $MaxPlayers
    }
    Start-Sleep -Seconds 5
    Get-PoshCS2-Status
}
function Stop-PoshCS2-Server {
    param (
        [string]$ComputerName = $null
    )
    if ($ComputerName) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $Processes = Get-CimInstance Win32_Process -Filter "Name LIKE 'cs2%'"
            foreach ($Process in $Processes) {
                if ($Process.CommandLine -like "*-dedicated*") {
                    Stop-Process -Id $Process.ProcessId -Force
                    Write-Host "Stopped CS2 Dedicated Server (PID: $($Process.ProcessId))" -ForegroundColor Yellow
                }
            }
        }
    }
    else {
        $Processes = Get-CimInstance Win32_Process -Filter "Name LIKE 'cs2%'"
        foreach ($Process in $Processes) {
            if ($Process.CommandLine -like "*-dedicated*") {
                Stop-Process -Id $Process.ProcessId -Force
                Write-Host "Stopped CS2 Dedicated Server (PID: $($Process.ProcessId))" -ForegroundColor Yellow
            }
        }
    }
}
function Restart-PoshCS2-Server {
    param (
        [string]$ComputerName = $null
    )
    if ($ComputerName) {
        Stop-PoshCS2-Server -ComputerName $ComputerName
        Start-PoshCS2-Server -ComputerName $ComputerName
    }
    else {
        Stop-PoshCS2-Server
        Start-PoshCS2-Server
    }
}

function Get-PoshCS2-RconProfile {
    param (
        [string]$Target = "default"
    )
    $ConfFile = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
    $RconProfile = $ConfFile.$Target
    if (-not $RconProfile) {
        $AvailableProfiles = ($ConfFile.PSObject.Properties | Select-Object -ExpandProperty Name) -join ', '
        Throw "RCON profile '$Target' not found in rcon.json. Available profiles: $AvailableProfiles"
    }
    return $RconProfile
}

function Send-PoshCS2-Command {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("matchzy_loadmatch", "matchzy_listbackups", "matchzy_loadbackup", "css_start", "css_forcepause", "css_forceunpause", "css_endmatch", 'css_asay', 'mp_terminate_match', 'host_workshop_map', 'status')]
        [string]$Command,
        [string]$Argument = $null,
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $conf = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
                $conf.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
            })]
        [string]$Target = "default",
        [string]$Address = $null,
        [PSCredential]$Password = $null 
    )

    $CommandsRequiringArgument = @(
        'matchzy_loadmatch',
        'matchzy_loadbackup',
        'mp_terminate_match',
        'css_asay',
        'host_workshop_map'
    )

    if ($Command -in $CommandsRequiringArgument -and [string]::IsNullOrWhiteSpace($Argument)) {
        Throw "The command '$Command' requires an argument."
    }

    # Resolve address and password: inline overrides take priority over profiles
    if ($Address -and $Password) {
        $RconAddress = $Address
        $RconPassword = $Password.GetNetworkCredential().Password
    }
    elseif ($Address -or $Password) {
        Throw "Both -Address and -Password must be provided together for inline override."
    }
    else {
        $RconProfile = Get-PoshCS2-RconProfile -Target $Target
        $RconAddress = $RconProfile.address
        $RconPassword = $RconProfile.password
    }

    # Point this to where you saved rcon.exe
    $RconPath = "E:\CS2\resources\rcon.exe"

    & $RconPath -a $RconAddress -p $RconPassword "$Command $Argument"
}                                         

function Get-PoshCS2-Status {
    param (
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $conf = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
                $conf.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
            })]
        [string]$Target = "default"
    )
    $Status = Send-PoshCS2-Command -Command "status" -Target $Target
}
function Setup-PoshCS2-WorkshopMap {
    param (
        [validateSet("3666944764", '3663186989', '3643838992')]
        [String]$WorkshopId,
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $conf = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
                $conf.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
            })]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "host_workshop_map" -Argument $WorkshopId -Target $Target
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
        [switch]$Force,
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $conf = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
                $conf.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
            })]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "matchzy_loadmatch" -Argument $MatchFile -Target $Target

    if ($Force) {
        Send-PoshCS2-Command -Command "css_start" -Target $Target
    }
}

function Start-PoshCS2-Match {
    param (
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $conf = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
                $conf.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
            })]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "css_start" -Target $Target
}

function Stop-PoshCS2-Match {
    param (
        [switch]$Confirm,
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $conf = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
                $conf.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
            })]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "css_endmatch" -Target $Target
}
#FIX ME
function Pause-PoshCS2-Match {
    param (
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $conf = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
                $conf.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
            })]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "css_forcepause" -Target $Target
}
#FIX ME
function Unpause-PoshCS2-Match {
    param (
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $conf = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
                $conf.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
            })]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "css_forceunpause" -Target $Target
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
        [string]$BackupFile,
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $conf = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
                $conf.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
            })]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "matchzy_loadbackup" -Argument $BackupFile -Target $Target
}
function Send-Posh2CS-Message {
    param(
        [String]
        $Message,
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $conf = Get-Content E:\CS2\resources\rcon.json | ConvertFrom-Json
                $conf.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
            })]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "css_asay" -Argument $Message -Target $Target
}
Export-ModuleMember -Function *
