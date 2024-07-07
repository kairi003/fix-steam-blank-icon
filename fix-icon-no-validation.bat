@echo off
REM Check if at least one argument is provided
if "%~1" == "" (
    echo fix-icon.bat path1 [path2 ...]
    echo args: path1 path2 ... - Paths to steam game shortcut files
    exit /b 1
)

for %%i in (%*) do call :fix_icon %%i

echo All done.

exit /b 0


REM ------------------------------------------------------------
REM Function to fix the icon
REM ------------------------------------------------------------
:fix_icon
setlocal

echo Processing: %~1


REM Read the file line by line
for /f "usebackq delims=" %%i in ("%~1") do set "%%~i" 2>nul
REM Validate the URL and extract the game ID
if "%URL:~0,18%" == "steam://rungameid/" set "gameid=%URL:~18%"
REM Extract the icon file name
for %%f in ("%IconFile%") do set "icon_name=%%~nxf"

REM Download the icon file
REM Icon location is written on: https://steamdb.info/app/{gameid}/info/
set "icon_url=https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/%gameid%/%icon_name%"
echo Downloading icon file: "%icon_url%"
curl -o "%IconFile%" "%icon_url%"

endlocal

exit /b 0
