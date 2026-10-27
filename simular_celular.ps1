# Script para simular celular no Google Chrome com DevicePreview
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Iniciando Simulador de Celular - Agenda App           " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$env:JAVA_HOME = "C:\Program Files\Android\openjdk\jdk-21.0.8"
$env:ANDROID_HOME = "C:\Program Files (x86)\Android\android-sdk"
$env:Path = "C:\src\flutter\bin;$($env:JAVA_HOME)\bin;$($env:ANDROID_HOME)\platform-tools;$($env:Path)"

Set-Location -Path $PSScriptRoot

Write-Host "[1/2] Obtendo dependencias do Flutter..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n[2/2] Iniciando aplicativo no Google Chrome com a moldura de celular..." -ForegroundColor Yellow
Write-Host "(Dica: Voce pode trocar de modelo de smartphone, alternar orientacao e testar a interface diretamente no navegador!)`n" -ForegroundColor Green

flutter run -d chrome
