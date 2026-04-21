@echo off
setlocal EnableDelayedExpansion

echo ==========================================
echo Steam Icon Fixer - FINAL ULTRA ESTAVEL
echo ==========================================

set "LOGFILE=%~dp0steam_icon_fix_log.txt"
echo Log iniciado em %date% %time% > "%LOGFILE%"

if "%~1"=="" (
    echo Uso: arraste arquivos .url para o .bat
    pause
    exit /b 1
)

set "ALTEROU=0"

for %%i in (%*) do (
    call :process_file "%%~i"
)

echo.
echo ==========================================
echo Finalizado!
echo Log: %LOGFILE%
echo ==========================================

if "%ALTEROU%"=="1" (
    echo.
    echo Atualizando cache de icones...

    timeout /t 2 >nul

    call :restart_explorer

    echo Cache reconstruido!
) else (
    echo Nenhuma alteracao necessaria.
)

pause
exit /b 0


REM ==========================================
REM PROCESSAR ARQUIVO
REM ==========================================
:process_file

set "FILE=%~1"
echo.
echo Processando: %FILE%
echo ------------------------------ >> "%LOGFILE%"
echo Processando: %FILE% >> "%LOGFILE%"

if /I not "%~x1"==".url" exit /b
if not exist "%FILE%" exit /b

set "URL="
set "IconFile="
set "gameid="

for /f "usebackq tokens=1,* delims==" %%A in ("%FILE%") do (
    if /I "%%A"=="URL" set "URL=%%B"
    if /I "%%A"=="IconFile" set "IconFile=%%B"
)

if "!URL!"=="" exit /b

if /I "!URL:~0,18!"=="steam://rungameid/" (
    set "gameid=!URL:~18!"
) else (
    exit /b
)

if "!IconFile!"=="" exit /b

for %%F in ("!IconFile!") do (
    set "icon_name=%%~nxF"
    set "icon_dir=%%~dpF"
)

if not exist "!icon_dir!" mkdir "!icon_dir!" >nul 2>&1

if exist "!IconFile!" (
    attrib -r -h -s "!IconFile!" >nul 2>&1
    del /f /q "!IconFile!" >nul 2>&1
)

set "icon_url=https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/!gameid!/!icon_name!"

echo Tentando baixar: !icon_url! >> "%LOGFILE%"

curl -L -f -o "!IconFile!" "!icon_url!" >nul 2>&1

if errorlevel 1 (
    echo [WARN] Falha direta. Tentando fallback... >> "%LOGFILE%"

    set "fallback=%localappdata%\Temp\!icon_name!"

    curl -L -f -o "!fallback!" "!icon_url!" >nul 2>&1

    if errorlevel 1 (
        echo [ERRO] Falha total no download >> "%LOGFILE%"
        exit /b
    )

    call :update_url "!FILE!" "!fallback!"

    echo [OK] Fallback usado >> "%LOGFILE%"
    set "ALTEROU=1"
    exit /b
)

for %%S in ("!IconFile!") do set "size=%%~zS"

if !size! LSS 2048 (
    del /f /q "!IconFile!"
    echo [ERRO] Arquivo invalido >> "%LOGFILE%"
    exit /b
)

echo [SUCESSO] Icone OK >> "%LOGFILE%"
set "ALTEROU=1"

copy /b "%FILE%" +,, >nul

exit /b


REM ==========================================
REM ATUALIZAR .URL
REM ==========================================
:update_url

set "file=%~1"
set "newicon=%~2"
set "tempfile=%file%.tmp"

(
for /f "usebackq delims=" %%L in ("%file%") do (
    echo %%L | findstr /I "^IconFile=" >nul
    if errorlevel 1 (
        echo %%L
    ) else (
        echo IconFile=%newicon%
    )
)
) > "%tempfile%"

move /Y "%tempfile%" "%file%" >nul

exit /b


REM ==========================================
REM RESTART EXPLORER (ROBUSTO)
REM ==========================================
:restart_explorer

echo Reiniciando Explorer...

:restart_explorer

echo Reiniciando Explorer (modo seguro)...

taskkill /IM explorer.exe /F >nul 2>&1

timeout /t 2 >nul

ie4uinit.exe -ClearIconCache >nul 2>&1

del /A /Q "%localappdata%\IconCache.db" >nul 2>&1
del /A /F /Q "%localappdata%\Microsoft\Windows\Explorer\iconcache*" >nul 2>&1

REM Método mais confiável
start "" cmd /c "start explorer.exe"

REM fallback forte
timeout /t 3 >nul
tasklist | find /I "explorer.exe" >nul
if errorlevel 1 (
    echo Tentando via userinit...
    start "" "%windir%\System32\userinit.exe"
)

exit /b