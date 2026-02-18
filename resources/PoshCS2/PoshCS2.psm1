$script:PoshCS2Config = @{
    ServersJsonPath = 'E:\CS2\resources\servers.json'
    RconJsonPath    = 'E:\CS2\resources\rcon.json'
    ServersJson     = $null
    Active          = $null
}

function Import-PoshCS2-Variables {
    param(
        [Parameter(Position = 0)]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $path = $script:PoshCS2Config.ServersJsonPath
                if (Test-Path $path) {
                    $json = Get-Content -Raw -Path $path | ConvertFrom-Json
                    $json.psobject.properties.name | Where-Object { $_ -like "$wordToComplete*" }
                }
            })]$Name,
        [string]$ServersJsonPath = $script:PoshCS2Config.ServersJsonPath
    )
    
    # Update the module-scoped path if provided
    if ($PSBoundParameters.ContainsKey('ServersJsonPath')) {
        $script:PoshCS2Config.ServersJsonPath = $ServersJsonPath
    }
    
    # Load and cache the servers configuration
    $script:PoshCS2Config.ServersJson = Get-Content -Path $script:PoshCS2Config.ServersJsonPath | ConvertFrom-Json

    # Set active profile
    if ($Name -and $script:PoshCS2Config.ServersJson.$Name) {
        $script:PoshCS2Config.Active = $script:PoshCS2Config.ServersJson.$Name
    }
    else {
        # Fallback to first profile if not specified or not found
        $FirstProfileName = $script:PoshCS2Config.ServersJson.PSObject.Properties.Name[0]
        $script:PoshCS2Config.Active = $script:PoshCS2Config.ServersJson.$FirstProfileName
    }

    return $script:PoshCS2Config.Active
}

# Helper function to ensure configuration is loaded
function Test-PoshCS2Config {
    if ($null -eq $script:PoshCS2Config.Active) {
        Write-Warning "PoshCS2 active configuration is not loaded. Attempting to load default..."
        Import-PoshCS2-Variables > $null
        if ($null -eq $script:PoshCS2Config.Active) {
            throw "PoshCS2 configuration could not be loaded. Please verify '$($script:PoshCS2Config.ServersJsonPath)' exists and is valid."
        }
    }
    else {
        Write-Host "PoshCS2 configuration is loaded." -ForegroundColor Green
        Write-Host "Active Profile: $($script:PoshCS2Config.Active)" -ForegroundColor Green  
    }
}

function Install-PoshCS2-ServerResources {
    param (
        [string]$ServerPath = $script:PoshCS2Config.Active.ServerPath,
        [string]$ResourcesPath = $script:PoshCS2Config.Active.ResourcesPath,
        [switch]$Force
    )
    Test-PoshCS2Config

    Write-Host "Checking directories..." -ForegroundColor Cyan
    $CSGOPath = Join-Path $ServerPath "game\csgo" 
    $CSGOAddonsPath = Join-Path $CSGOPath "addons"
    $GameInfoPath = Join-Path $CSGOPath "gameinfo.gi"
    
    if ($ServerPath -eq "E:\CS2\relay") {
       
        Write-Host "Copy Relay.cfg to path: $("$CSGOPath\cfg\")" -ForegroundColor Cyan
        Copy-Item -Path "$($script:PoshCS2Config.Active.ResourcesPath)\relay.cfg" -Destination "$CSGOPath\cfg\server.cfg" -Force -Verbose
        Write-Host "Relay.cfg copied successfully." -ForegroundColor Green

        Write-Host "Relay server does not require additional resources"

        return
    }

    $ErrorActionPreference = "Stop"

    $MetamodDownloadUrl = "https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1384-windows.zip"
    $CounterStrikeSharpDownloadUrl = "https://github.com/roflmuffin/CounterStrikeSharp/releases/download/v1.0.362/counterstrikesharp-with-runtime-windows-1.0.362.zip"
    $MatchZyDownloadUrl = "https://github.com/shobhit-pathak/MatchZy/releases/download/0.8.15/MatchZy-0.8.15.zip"

   

    Write-Host "Installing Metamod" -ForegroundColor Cyan
    if (((Test-Path $CSGOAddonsPath\metamod) -and !$Force)) {
        # If force is not enabled and metamod exists, skip download and installation
        Write-Host "Metamod already exists. Skipping download and installation." -ForegroundColor Yellow
    }
    else {
        # Download and install metamod
        Invoke-WebRequest $MetamodDownloadUrl -OutFile "$($script:PoshCS2Config.Active.ResourcesPath)\metamod.zip"
        Expand-Archive -Path "$($script:PoshCS2Config.Active.ResourcesPath)\metamod.zip" -DestinationPath $CSGOPath -Force 
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
        Invoke-WebRequest $CounterStrikeSharpDownloadUrl -OutFile "$($script:PoshCS2Config.Active.ResourcesPath)\cs2sharp-runtime.zip"
        Expand-Archive -Path "$($script:PoshCS2Config.Active.ResourcesPath)\cs2sharp-runtime.zip" -DestinationPath $CSGOPath  -Force
        Write-Host "CounterStrikeSharp Runtime Installed" -ForegroundColor Green
    }

    Write-Host "Installing MatchZy" -ForegroundColor Cyan
    if ((Test-Path $CSGOAddonsPath\counterstrikesharp\plugins\MatchZy) -and !$Force) {
        # If force is not enabled and MatchZy exists, skip download and installation
        Write-Host "MatchZy already exists. Skipping download and installation." -ForegroundColor Yellow
    }
    else {
        # Download and install MatchZy
        Invoke-WebRequest $MatchZyDownloadUrl -OutFile "$($script:PoshCS2Config.Active.ResourcesPath)\MatchZy.zip"
        Expand-Archive -Path "$($script:PoshCS2Config.Active.ResourcesPath)\MatchZy.zip" -DestinationPath $CSGOPath -Force
        Write-Host "MatchZy Installed" -ForegroundColor Green
    }

    Write-Host "Copy Server.cfg to path: $("$CSGOPath\cfg\")" -ForegroundColor Cyan
    Copy-Item -Path "$($script:PoshCS2Config.Active.ResourcesPath)\server.cfg" -Destination "$CSGOPath\cfg\" -Force -Verbose
    Write-Host "Server.cfg copied successfully." -ForegroundColor Green

    Write-Host "Copy config.cfg to path: $("$CSGOPath\cfg\MatchZy\")" -ForegroundColor Cyan
    Copy-Item -Path "$($script:PoshCS2Config.Active.ResourcesPath)\config.cfg" -Destination "$CSGOPath\cfg\MatchZy\" -Force -Verbose
    Write-Host "config.cfg copied successfully." -ForegroundColor Green
 
    Write-Host "Copy secrets.cfg to path: $("$CSGOPath\cfg\")" -ForegroundColor Cyan
    Copy-Item -Path "$($script:PoshCS2Config.Active.ResourcesPath)\secrets.cfg" -Destination "$CSGOPath\cfg\" -Force -Verbose
    Write-Host "secrets.cfg copied successfully." -ForegroundColor Green

    Write-Host "Copy admins.json to path: $("$CSGOPath\addons\counterstrikesharp\configs\")" -ForegroundColor Cyan
    Copy-Item -Path "$($script:PoshCS2Config.Active.ResourcesPath)\admins.json" -Destination "$CSGOPath\addons\counterstrikesharp\configs\" -Force -Verbose
    Write-Host "admins.json copied successfully." -ForegroundColor Green

}
function Update-PoshCS2-Server {
    param (
        [string]$SteamCMDPath = $script:PoshCS2Config.Active.SteamCMDPath,
        [string]$ServerPath = $script:PoshCS2Config.Active.ServerPath,
        [string]$ComputerName = $null
    )
    Test-PoshCS2Config

    if ($ComputerName) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($sp)
            & $sp +force_install_dir $ServerPath +login anonymous +app_update 730 validate +quit
        } -ArgumentList $SteamCMDPath
    }
    else {
        & $SteamCMDPath +force_install_dir $ServerPath +login anonymous +app_update 730 validate +quit

    }

    Write-Host "Update completed successfully." -ForegroundColor Green
}

function Start-PoshCS2-Server {
    param (          
        $ServerPath = $script:PoshCS2Config.Active.ServerExecutablePath,
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
function Start-PoshCS2-Relay {
    param (          
        $ServerPath = "E:\CS2\relay\game\bin\win64\cs2.exe",
        $MainIP = "127.0.0.1", # The IP of your Match Server
        $MainTVPort = 27020,   # The TV Port of your Match Server
        $RelayPort = 27016,    # Different from 27015
        $RelayTVPort = 27021  # Different from 27020
    )

    Write-Host "Starting CSTV Relay Shield with isolated data folder..." -ForegroundColor Cyan
    Write-Host "Connecting to Main Server at $MainIP`:$MainTVPort" -ForegroundColor Yellow


    while ($true) {
        Write-Host "--- Starting Relay Shield ---" -ForegroundColor Green
        
        # We use Start-Process -Wait so the loop "pauses" while the server is running.
        # Once the server hits 'HLTVSTOP' and closes, the loop continues and restarts it.
        Start-Process -FilePath $ServerPath -ArgumentList "-dedicated -notextmode -console -port $RelayPort +tv_port $RelayTVPort +tv_relay $MainIP`:$MainTVPort +exec server.cfg" -Wait

        Write-Host "--- Relay Uplink lost or Demo-spike detected. Restarting in 4 seconds... ---" -ForegroundColor Yellow
        Start-Sleep -Seconds 4
    }

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
        [validateset("default", "lan-pc2")]
        [string]$Target = "default"
    )
    $ConfFile = Get-Content "$($script:PoshCS2Config.Active.RconConfigPath)" | ConvertFrom-Json
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
        [validateset("default", "lan-pc2")]
        [string]$Target = "default",
        [string]$Address = $null,
        [PSCredential]$Password = $null 
    )
    $ConfFile = Get-Content "$($script:PoshCS2Config.Active.RconConfigPath)" | ConvertFrom-Json
    $RconProfile = $ConfFile.$Target
    if (-not $RconProfile) {
        $AvailableProfiles = ($ConfFile.PSObject.Properties | Select-Object -ExpandProperty Name) -join ', '
        Throw "RCON profile '$Target' not found in rcon.json. Available profiles: $AvailableProfiles"
    }
    $RconAddress = $RconProfile.address
    $RconPassword = $RconProfile.password
    $RconPath = $script:PoshCS2Config.Active.RconPath
    
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
    $RconPath = $script:PoshCS2Config.Active.RconPath

    & $RconPath -a $RconAddress -p $RconPassword "$Command $Argument"
}                                         

function Get-PoshCS2-Status {
    param (
        [validateset("default", "lan-pc2")]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "status" -Target $Target
}
function Initialize-PoshCS2-WorkshopMap {
    param (
        [validateSet("3666944764", '3663186989', '3643838992')]
        [String]$WorkshopId,
        [validateset("default", "lan-pc2")]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "host_workshop_map" -Argument $WorkshopId -Target $Target
}

function Import-PoshCS2-Match {
    param (
        [Parameter(Mandatory = $true)]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $serverPath = $script:PoshCS2Config.Active.ServerPath
                if (-not $serverPath) { $serverPath = "E:\CS2" }
                $searchPath = Join-Path $serverPath "server\game\csgo\*.json"
                Get-ChildItem -Path $searchPath | Where-Object { $_.Name -like "$wordToComplete*" } | Select-Object -ExpandProperty Name
            })]
        [string]$MatchFile,
        [validateset("default", "lan-pc2")]
        [string]$Target = "default",
        [switch]$Force
    )
    Send-PoshCS2-Command -Command "matchzy_loadmatch" -Argument $MatchFile -Target $Target

    if ($Force) {
        Send-PoshCS2-Command -Command "css_start" -Target $Target
    }
}

function Start-PoshCS2-Match {
    param (
        [validateset("default", "lan-pc2")]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "css_start" -Target $Target
}

function Stop-PoshCS2-Match {
    param (
        [validateset("default", "lan-pc2")]
        [string]$Target = "default",
        [switch]$Confirm
    )
    Send-PoshCS2-Command -Command "css_endmatch" -Target $Target
}

function Suspend-PoshCS2-Match {
    param (
        [validateset("default", "lan-pc2")]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "css_forcepause" -Target $Target
}

function Resume-PoshCS2-Match {
    param (
        [validateset("default", "lan-pc2")]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "css_forceunpause" -Target $Target
}

function Get-PoshCS2-RoundBackups {
    param (
        [validateset("default", "lan-pc2")]
        [string]$Target = "default"
    )   
    return (Get-ChildItem "$($script:PoshCS2Config.Active.ServerPath)\game\csgo\MatchZyDataBackup\*" | Select-Object -ExpandProperty Name)
}

function Restore-PoshCS2-Round {
    param (
        [Parameter(Mandatory = $true)]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $serverPath = $script:PoshCS2Config.Active.ServerPath
                if (-not $serverPath) { $serverPath = "E:\CS2" }
                $searchPath = Join-Path $serverPath "game\csgo\MatchZyDataBackup\*"
                Get-ChildItem -Path $searchPath | Where-Object { $_.Name -like "$wordToComplete*" } | Select-Object -ExpandProperty Name
            })]
        [string]$BackupFile,
        [validateset("default", "lan-pc2")]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "matchzy_loadbackup" -Argument $BackupFile -Target $Target
}
function Send-Posh2CS-Message {
    param(
        [String]
        $Message,
        [validateset("default", "lan-pc2")]
        [string]$Target = "default"
    )
    Send-PoshCS2-Command -Command "css_asay" -Argument $Message -Target $Target
}

# Initialize variables on module load
Import-PoshCS2-Variables -Name "local"

Export-ModuleMember -Function *
