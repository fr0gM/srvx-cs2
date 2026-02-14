# 1. Instalacja/Upgrade Servera
- git pull https://github.com/fr0gM/srvx-cs2
- .\steamcmd\steamcmd +runscript cs2-updater.txt
- . .\Install-CS2ServerResources.ps1 


# 2. Uruchomienie serwera

- .\server\game\bin\win64\cs2.exe -dedicated -usercon -console -port 27015 +tv_port 27020 +map de_mirage +sv_setsteamaccount XX +sv_logfile 1 -maxplayers 16

## Zaladowanie meczu
- matchzy_loadmatch mecz.json


## Restart meczu w trakcie
- css_endmatch
- css_restart




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


