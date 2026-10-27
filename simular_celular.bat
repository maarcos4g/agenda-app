@echo off
title Simulador de Celular - Agenda App
echo ========================================================
echo   Iniciando Simulador de Celular - Projeto Agenda App
echo ========================================================
echo.

set "JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8"
set "ANDROID_HOME=C:\Program Files (x86)\Android\android-sdk"
set "PATH=C:\src\flutter\bin;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

cd /d "%~dp0"

echo [1/2] Verificando dependencias do projeto...
call flutter pub get

echo.
echo [2/2] Abrindo aplicativo com o simulador de smartphone no Google Chrome...
echo (Voce vera uma moldura realista de celular com opcoes de rotacao, troca de modelo e toque!)
echo.
call flutter run -d chrome

echo.
pause
