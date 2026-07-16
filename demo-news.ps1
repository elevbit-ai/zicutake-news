# Demo rápida — Zicutake News Live (PowerShell)
# Uso: .\demo-news.ps1

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Zicutake-News.psm1') -Force

Write-Host "`n=== ZICUTAKE NEWS LIVE · DEMO ===" -ForegroundColor Cyan
Write-Host "Web: https://elevbit-ai.github.io/zicutake-news/`n" -ForegroundColor DarkGray

Write-Host ">> Manchetes (World)" -ForegroundColor Green
Get-ZicutakeNews -Category World -Top 5 | Format-Table Title, Source -Wrap

Write-Host "`n>> Mercados" -ForegroundColor Green
Get-ZicutakeMarkets | Format-Table Pair, Rate, Date

Write-Host "`n>> Crypto" -ForegroundColor Green
Get-ZicutakeCrypto | Format-Table Asset, USD, BRL, Change24hPct

Write-Host "`n>> Wikipedia" -ForegroundColor Green
Get-ZicutakeWiki -Query 'Inteligência artificial' | Format-List Title, Description, Url

Write-Host "`nDemo concluída. Use Watch-ZicutakeNews para monitoramento contínuo." -ForegroundColor Yellow
