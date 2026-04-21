@echo off
setlocal

echo ==========================================
echo RESET COMPLETO DO DESKTOP (SEGURO)
echo ==========================================
echo.
echo Isso vai:
echo - Limpar cache de icones
echo - Reiniciar o Explorer
echo - Criar um Desktop novo
echo - Fazer backup do antigo
echo.
pause

REM ==========================================
REM DEFINIR CAMINHOS
REM ==========================================
set "USERDIR=%USERPROFILE%"
set "DESKTOP=%USERPROFILE%\Desktop"
set "BACKUP=%USERPROFILE%\Desktop_backup_%RANDOM%"

echo.
echo Backup sera criado em:
echo %BACKUP%
echo.
pause

REM ==========================================
REM MATAR EXPLORER
REM ==========================================
echo.
echo Fechando Explorer...
taskkill /IM explorer.exe /F >nul 2>&1

timeout /t 2 >nul

REM ==========================================
REM LIMPAR CACHE
REM ==========================================
echo Limpando cache de icones...

del /A /Q "%localappdata%\IconCache.db" >nul 2>&1
del /A /F /Q "%localappdata%\Microsoft\Windows\Explorer\iconcache*" >nul 2>&1
del /A /F /Q "%localappdata%\Microsoft\Windows\Explorer\thumbcache*" >nul 2>&1

REM ==========================================
REM BACKUP DO DESKTOP
REM ==========================================
echo Fazendo backup do Desktop...

if exist "%DESKTOP%" (
    ren "%DESKTOP%" "Desktop_backup_%RANDOM%"
)

REM ==========================================
REM RECRIAR DESKTOP
REM ==========================================
echo Criando novo Desktop...
mkdir "%DESKTOP%" >nul 2>&1

REM ==========================================
REM REINICIAR EXPLORER (ROBUSTO)
REM ==========================================
echo Reiniciando Explorer...

start "" "%windir%\explorer.exe"

timeout /t 3 >nul

tasklist | find /I "explorer.exe" >nul
if errorlevel 1 (
    echo Explorer nao iniciou, tentando novamente...
    start "" "%windir%\explorer.exe"
)

echo.
echo ==========================================
echo CONCLUIDO!
echo ==========================================
echo.
echo Seu Desktop antigo foi salvo como:
echo Desktop_backup_XXXXX
echo.
echo Agora:
echo 1. Teste colocando 1 atalho novo
echo 2. Se funcionar, mova os arquivos aos poucos
echo.

pause