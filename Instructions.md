# 1. Instalacja/Upgrade Servera
- git pull https://github.com/fr0gM/srvx-cs2
- Import-Module .\resources\PoshCS2\PoshCS2.psm1 -Verbose
- Update-PoshCS2-Server
- Install-PoshCS2-ServerResources -Force
  
# 2. Uruchomienie serwera
- Start-PoshCS2-Server
- Stop-PoshCS2-Server
- Restart-PoshCS2-Server

## Zaladowanie meczu
- Load-PoshCS2-Match mecz.json
- Load-PoshCS2-Match mecz.json -Force
- Start-PoshCS2-Match
  
## Restart meczu w trakcie
- Stop-PoshCS2-Match
- Restart-PoshCS2-Match
- Pause-PoshCS2-Match
- Resume-PoshCS2-Match

# 3. Dodatowe info o pluginach
-------------------
## metamod
https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1387-windows.zip

Invoke-WebRequest https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1387-windows.zip -OutFile E:\CS2\resources\metamod.zip

Download the latest dev build from the releases page
Move the addons folder to your game/csgo folder
Edit gameinfo.gi in game/csgo and add Game csgo/addons/metamod to the SearchPaths section

## cs2sharp
Extract the addons folder to the csgo/ directory of the dedicated server. The contents of your addons folder should contain both the counterstrikesharp folder and the metamod folder

Invoke-WebRequest https://github.com/roflmuffin/CounterStrikeSharp/releases/download/v1.0.362/counterstrikesharp-with-runtime-windows-1.0.362.zip -OutFile E:\CS2\resources\cs2sharp-runtime.zip

## Matchzy
https://github.com/shobhit-pathak/MatchZy/releases/download/0.8.15/MatchZy-0.8.15.zip

Download the latest MatchZy release and extract the files to the csgo/ directory of the dedicated server.
Verify the installation by typing css_plugins list and you should see MatchZy by WD- listed there.

Invoke-WebRequest https://github.com/shobhit-pathak/MatchZy/releases/download/0.8.15/MatchZy-0.8.15.zip -OutFile E:\CS2\resources\MatchZy.zip


