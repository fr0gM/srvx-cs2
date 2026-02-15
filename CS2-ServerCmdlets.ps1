function Start-CS2-Server {
    param (          
        $ServerPath = "E:\CS2\server\game\bin\win64\cs2.exe",
        $Port = 27015,
        $TVPort = 27020,
        $Map = "de_mirage",
        $SteamAccount = "XX",
        $LogFile = 1,
        $MaxPlayers = 16
    )

    & $ServerPath -dedicated -usercon -console -port $Port +tv_port $TVPort +map $Map +sv_setsteamaccount $SteamAccount +sv_logfile $LogFile -maxplayers $MaxPlayers

}
function Stop-CS2-Server {
    $Processes = Get-CimInstance Win32_Process -Filter "Name LIKE 'cs2%'"
    foreach ($Process in $Processes) {
        if ($Process.CommandLine -like "*-dedicated*") {
            Stop-Process -Id $Process.ProcessId -Force
            Write-Host "Stopped CS2 Dedicated Server (PID: $($Process.ProcessId))" -ForegroundColor Yellow
        }
    }
}
function Restart-CS2-Server {
    Stop-CS2-Server
    Start-CS2-Server
}

function Send-CS2 {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("matchzy_loadmatch", "matchzy_listbackups", "matchzy_loadbackup", "css_start", "css_pause", "css_unpause", "css_endmatch")]
        [string]$Command,
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                Get-ChildItem "E:\CS2\server\game\csgo\*.json" | Select-Object -ExpandProperty Name
            })
        ] 
        [string]$Argument = $null
    )

    $CommandsRequiringArgument = @(
        'matchzy_loadmatch',
        'matchzy_loadbackup'
    )

    if ($Command -in $CommandsRequiringArgument -and [string]::IsNullOrWhiteSpace($Argument)) {
        Throw "The command '$Command' requires an argument."
    }

    $ConfFile = Get-content E:\cs2\resources\rcon.json | ConvertFrom-Json

    # Point this to where you saved rcon.exe
    $RconPath = "E:\CS2\resources\rcon.exe"

    & $RconPath -a $ConfFile.default.address -p $ConfFile.default.password "$Command $Argument"
}                                         
