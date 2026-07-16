@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul 2>&1
title Zicutake News Live

set "ROOT=%~dp0"
set "MODULE=%ROOT%Zicutake-News.psm1"
set "PS=powershell.exe -NoProfile -ExecutionPolicy Bypass"

if not exist "%MODULE%" (
  echo [ERRO] Modulo nao encontrado: %MODULE%
  echo Baixe de: https://github.com/elevbit-ai/zicutake-news
  exit /b 1
)

set "CMD=%~1"
if "%CMD%"=="" set "CMD=menu"

if /I "%CMD%"=="help"  goto :help
if /I "%CMD%"=="/?"    goto :help
if /I "%CMD%"=="-h"    goto :help
if /I "%CMD%"=="menu"  goto :menu
if /I "%CMD%"=="news"  goto :news
if /I "%CMD%"=="world" goto :news
if /I "%CMD%"=="tech"  goto :tech
if /I "%CMD%"=="usa"   goto :usa
if /I "%CMD%"=="crypto" goto :crypto_news
if /I "%CMD%"=="business" goto :business
if /I "%CMD%"=="science" goto :science
if /I "%CMD%"=="brazil" goto :brazil
if /I "%CMD%"=="markets" goto :markets
if /I "%CMD%"=="fx" goto :markets
if /I "%CMD%"=="coins" goto :coins
if /I "%CMD%"=="wiki" goto :wiki
if /I "%CMD%"=="search" goto :search
if /I "%CMD%"=="web" goto :web
if /I "%CMD%"=="watch" goto :watch
if /I "%CMD%"=="all" goto :all
if /I "%CMD%"=="test" goto :test

echo Comando desconhecido: %CMD%
echo.
goto :help

:help
echo.
echo  ============================================
echo   ZICUTAKE NEWS LIVE - comandos no CMD
echo  ============================================
echo.
echo   zicutake.cmd news          Manchetes mundo
echo   zicutake.cmd tech          Tecnologia
echo   zicutake.cmd usa           EUA
echo   zicutake.cmd crypto        Crypto news
echo   zicutake.cmd business      Economia
echo   zicutake.cmd science       Ciencia
echo   zicutake.cmd brazil        Brasil
echo   zicutake.cmd markets       Cambio USD
echo   zicutake.cmd coins         Precos crypto
echo   zicutake.cmd search TEXTO  Buscar noticias
echo   zicutake.cmd wiki TEMA     Wikipedia
echo   zicutake.cmd watch         Atualiza a cada 60s
echo   zicutake.cmd all           Tudo de uma vez
echo   zicutake.cmd web           Abre o site
echo   zicutake.cmd test          Testa feeds
echo   zicutake.cmd menu          Menu interativo
echo.
echo  Site: https://elevbit-ai.github.io/zicutake-news/
echo  Autor: Joaquim Pedro de Morais Filho
echo.
exit /b 0

:menu
cls
echo.
echo  ============================================
echo   ZICUTAKE NEWS LIVE
echo  ============================================
echo   [1] Noticias Mundo
echo   [2] Tecnologia
echo   [3] EUA
echo   [4] Crypto news
echo   [5] Economia
echo   [6] Mercados (cambio)
echo   [7] Precos crypto
echo   [8] Buscar...
echo   [9] Wikipedia...
echo   [A] Tudo
echo   [W] Abrir site
echo   [T] Testar feeds
echo   [0] Sair
echo  ============================================
set /p "OPT=Escolha: "
if "%OPT%"=="1" goto :news
if "%OPT%"=="2" goto :tech
if "%OPT%"=="3" goto :usa
if "%OPT%"=="4" goto :crypto_news
if "%OPT%"=="5" goto :business
if "%OPT%"=="6" goto :markets
if "%OPT%"=="7" goto :coins
if /I "%OPT%"=="8" goto :search_prompt
if /I "%OPT%"=="9" goto :wiki_prompt
if /I "%OPT%"=="A" goto :all
if /I "%OPT%"=="W" goto :web
if /I "%OPT%"=="T" goto :test
if "%OPT%"=="0" exit /b 0
goto :menu

:search_prompt
set /p "Q=Buscar: "
if "%Q%"=="" goto :menu
%PS% -Command "Import-Module '%MODULE%' -Force; Get-ZicutakeNews -Query '%Q%' -Top 12 | Format-Table Title,Source -Wrap; Write-Host ''; pause"
goto :menu

:wiki_prompt
set /p "W=Wikipedia: "
if "%W%"=="" goto :menu
%PS% -Command "Import-Module '%MODULE%' -Force; Get-ZicutakeWiki -Query '%W%' -Lang en | Format-List; Write-Host ''; pause"
goto :menu

:run_cat
%PS% -Command "Import-Module '%MODULE%' -Force; Write-Host '=== ZICUTAKE NEWS: %CAT% ===' -ForegroundColor Cyan; Get-ZicutakeNews -Category %CAT% -Top 12 | Format-Table Title,Source,Published -Wrap"
if errorlevel 1 (
  echo [ERRO] Falha ao carregar noticias.
  exit /b 1
)
exit /b 0

:news
set "CAT=World"
goto :run_cat

:tech
set "CAT=Tech"
goto :run_cat

:usa
set "CAT=USA"
goto :run_cat

:crypto_news
set "CAT=Crypto"
goto :run_cat

:business
set "CAT=Business"
goto :run_cat

:science
set "CAT=Science"
goto :run_cat

:brazil
set "CAT=Brazil"
goto :run_cat

:markets
%PS% -Command "Import-Module '%MODULE%' -Force; Write-Host '=== MERCADOS ===' -ForegroundColor Green; Get-ZicutakeMarkets | Format-Table Pair,Rate,Date,Provider -AutoSize"
exit /b %ERRORLEVEL%

:coins
%PS% -Command "Import-Module '%MODULE%' -Force; Write-Host '=== CRYPTO ===' -ForegroundColor Yellow; Get-ZicutakeCrypto | Format-Table Asset,USD,BRL,Change24hPct -AutoSize"
exit /b %ERRORLEVEL%

:wiki
if "%~2"=="" (
  echo Uso: zicutake.cmd wiki TEMA
  exit /b 1
)
set "TOPIC=%~2"
if not "%~3"=="" set "TOPIC=%~2 %~3"
if not "%~4"=="" set "TOPIC=%~2 %~3 %~4"
%PS% -Command "Import-Module '%MODULE%' -Force; Get-ZicutakeWiki -Query '%TOPIC%' -Lang en | Format-List"
exit /b %ERRORLEVEL%

:search
if "%~2"=="" (
  echo Uso: zicutake.cmd search TEXTO
  exit /b 1
)
set "Q=%~2"
if not "%~3"=="" set "Q=%~2 %~3"
if not "%~4"=="" set "Q=%~2 %~3 %~4"
if not "%~5"=="" set "Q=%~2 %~3 %~4 %~5"
%PS% -Command "Import-Module '%MODULE%' -Force; Get-ZicutakeNews -Query '%Q%' -Top 12 | Format-Table Title,Source -Wrap"
exit /b %ERRORLEVEL%

:watch
%PS% -Command "Import-Module '%MODULE%' -Force; Watch-ZicutakeNews -Category World -Seconds 60 -Top 8"
exit /b %ERRORLEVEL%

:web
%PS% -Command "Import-Module '%MODULE%' -Force; Open-ZicutakeNews"
echo Abrindo https://elevbit-ai.github.io/zicutake-news/
exit /b 0

:all
echo.
echo === ZICUTAKE NEWS ALL ===
%PS% -Command ^
  "Import-Module '%MODULE%' -Force; " ^
  "Write-Host '--- NEWS ---' -ForegroundColor Cyan; " ^
  "Get-ZicutakeNews -Category World -Top 6 | Format-Table Title,Source -Wrap; " ^
  "Write-Host '--- MARKETS ---' -ForegroundColor Green; " ^
  "Get-ZicutakeMarkets | Format-Table Pair,Rate -AutoSize; " ^
  "Write-Host '--- CRYPTO ---' -ForegroundColor Yellow; " ^
  "Get-ZicutakeCrypto | Format-Table Asset,USD,Change24hPct -AutoSize"
exit /b %ERRORLEVEL%

:test
echo Testando feeds e APIs...
%PS% -Command ^
  "$ErrorActionPreference='Continue'; " ^
  "Import-Module '%MODULE%' -Force; " ^
  "$ok=0; $fail=0; " ^
  "foreach($c in 'World','Tech','Crypto','Brazil'){ " ^
  "  try { $n=@(Get-ZicutakeNews -Category $c -Top 3); if($n.Count -gt 0){ Write-Host \"[OK] News $c ($($n.Count))\" -ForegroundColor Green; $ok++ } else { Write-Host \"[FAIL] News $c empty\" -ForegroundColor Red; $fail++ } } " ^
  "  catch { Write-Host \"[FAIL] News $c : $_\" -ForegroundColor Red; $fail++ } " ^
  "} " ^
  "try { $m=@(Get-ZicutakeMarkets); Write-Host \"[OK] Markets $($m.Count)\" -ForegroundColor Green; $ok++ } catch { Write-Host \"[FAIL] Markets $_\" -ForegroundColor Red; $fail++ } " ^
  "try { $c=@(Get-ZicutakeCrypto); Write-Host \"[OK] Crypto $($c.Count)\" -ForegroundColor Green; $ok++ } catch { Write-Host \"[FAIL] Crypto $_\" -ForegroundColor Red; $fail++ } " ^
  "try { $w=Get-ZicutakeWiki -Query 'Earth' -Lang en; Write-Host \"[OK] Wiki $($w.Title)\" -ForegroundColor Green; $ok++ } catch { Write-Host \"[FAIL] Wiki $_\" -ForegroundColor Red; $fail++ } " ^
  "Write-Host \"`nResultado: $ok ok, $fail falhas\" -ForegroundColor Cyan; " ^
  "if($fail -gt 0){ exit 1 } else { exit 0 }"
exit /b %ERRORLEVEL%
