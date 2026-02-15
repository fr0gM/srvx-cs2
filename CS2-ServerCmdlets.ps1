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
