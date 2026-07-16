#Requires -Version 5.1
<#
.SYNOPSIS
  Zicutake News Live — módulo PowerShell de IA / feeds em tempo real
.DESCRIPTION
  Comandos para puxar notícias, mercados, crypto e Wikipedia no terminal.
  Parte do ecossistema Zicutake · Elevbit / OpS · Joaquim Pedro de Morais Filho
.NOTES
  Web: https://elevbit-ai.github.io/zicutake-news/
  GitHub: https://github.com/elevbit-ai/zicutake-news
#>

Set-StrictMode -Version Latest

$script:ZicutakeNewsHome = 'https://elevbit-ai.github.io/zicutake-news/'

function Get-ZicutakeRssUrl {
    param(
        [ValidateSet('World','USA','Tech','Business','Crypto','Science')]
        [string]$Category = 'World',
        [ValidateSet('pt','en')]
        [string]$Lang = 'pt'
    )
    $map = @{
        World = @{
            pt = 'https://news.google.com/rss?hl=pt-BR&gl=BR&ceid=BR:pt-419'
            en = 'https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en'
        }
        USA = @{
            pt = 'https://news.google.com/rss/search?q=Estados+Unidos&hl=pt-BR&gl=BR&ceid=BR:pt-419'
            en = 'https://news.google.com/rss/search?q=United+States&hl=en-US&gl=US&ceid=US:en'
        }
        Tech = @{
            pt = 'https://news.google.com/rss/search?q=tecnologia&hl=pt-BR&gl=BR&ceid=BR:pt-419'
            en = 'https://news.google.com/rss/search?q=technology&hl=en-US&gl=US&ceid=US:en'
        }
        Business = @{
            pt = 'https://news.google.com/rss/search?q=economia+OR+mercado&hl=pt-BR&gl=BR&ceid=BR:pt-419'
            en = 'https://news.google.com/rss/search?q=business+OR+markets&hl=en-US&gl=US&ceid=US:en'
        }
        Crypto = @{
            pt = 'https://news.google.com/rss/search?q=bitcoin+OR+crypto&hl=pt-BR&gl=BR&ceid=BR:pt-419'
            en = 'https://news.google.com/rss/search?q=bitcoin+OR+cryptocurrency&hl=en-US&gl=US&ceid=US:en'
        }
        Science = @{
            pt = 'https://news.google.com/rss/search?q=ci%C3%AAncia&hl=pt-BR&gl=BR&ceid=BR:pt-419'
            en = 'https://news.google.com/rss/search?q=science&hl=en-US&gl=US&ceid=US:en'
        }
    }
    return $map[$Category][$Lang]
}

function Get-ZicutakeNews {
    <#
    .SYNOPSIS
      Busca manchetes em tempo real (Google News RSS).
    .EXAMPLE
      Get-ZicutakeNews -Category Tech -Top 8
    .EXAMPLE
      Get-ZicutakeNews -Query "inteligência artificial"
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('World','USA','Tech','Business','Crypto','Science')]
        [string]$Category = 'World',
        [string]$Query,
        [ValidateSet('pt','en')]
        [string]$Lang = 'pt',
        [int]$Top = 12
    )

    if ($Query) {
        $q = [uri]::EscapeDataString($Query)
        if ($Lang -eq 'pt') {
            $url = "https://news.google.com/rss/search?q=$q&hl=pt-BR&gl=BR&ceid=BR:pt-419"
        } else {
            $url = "https://news.google.com/rss/search?q=$q&hl=en-US&gl=US&ceid=US:en"
        }
    } else {
        $url = Get-ZicutakeRssUrl -Category $Category -Lang $Lang
    }

    Write-Verbose "RSS: $url"
    try {
        [xml]$rss = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30 | Select-Object -ExpandProperty Content
    } catch {
        Write-Error "Falha ao baixar feed: $_"
        return
    }

    $items = @($rss.rss.channel.item) | Select-Object -First $Top
    foreach ($it in $items) {
        [pscustomobject]@{
            Title       = [string]$it.title
            Link        = [string]$it.link
            Published   = [string]$it.pubDate
            Source      = if ($it.source.'#text') { [string]$it.source.'#text' } else { 'Google News' }
            Category    = $Category
            QueriedAt   = (Get-Date).ToString('s')
            Ecosystem   = 'Zicutake News Live'
        }
    }
}

function Get-ZicutakeMarkets {
    <#
    .SYNOPSIS
      Câmbio em tempo real (USD base via Frankfurter).
    #>
    [CmdletBinding()]
    param(
        [string[]]$To = @('BRL','EUR','GBP','JPY')
    )
    $symbols = ($To -join ',')
    $url = "https://api.frankfurter.app/latest?from=USD&to=$symbols"
    $data = Invoke-RestMethod -Uri $url -TimeoutSec 20
    foreach ($k in $data.rates.PSObject.Properties.Name) {
        [pscustomobject]@{
            Pair      = "USD/$k"
            Rate      = [decimal]$data.rates.$k
            Date      = $data.date
            Provider  = 'Frankfurter'
            QueriedAt = (Get-Date).ToString('s')
        }
    }
}

function Get-ZicutakeCrypto {
    <#
    .SYNOPSIS
      Preços de crypto (CoinGecko).
    #>
    [CmdletBinding()]
    param(
        [string[]]$Ids = @('bitcoin','ethereum','solana','dogecoin')
    )
    $idList = ($Ids -join ',')
    $url = "https://api.coingecko.com/api/v3/simple/price?ids=$idList&vs_currencies=usd,brl&include_24hr_change=true"
    $data = Invoke-RestMethod -Uri $url -TimeoutSec 20
    foreach ($id in $Ids) {
        $c = $data.$id
        if (-not $c) { continue }
        [pscustomobject]@{
            Asset        = $id
            USD          = $c.usd
            BRL          = $c.brl
            Change24hPct = $c.usd_24h_change
            Provider     = 'CoinGecko'
            QueriedAt    = (Get-Date).ToString('s')
        }
    }
}

function Get-ZicutakeWiki {
    <#
    .SYNOPSIS
      Resumo Wikipedia (PT ou EN).
    .EXAMPLE
      Get-ZicutakeWiki -Query "Brasil" -Lang pt
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,
        [ValidateSet('pt','en')]
        [string]$Lang = 'pt'
    )
    $searchUrl = "https://$Lang.wikipedia.org/w/api.php?action=query&list=search&srsearch=$([uri]::EscapeDataString($Query))&utf8=&format=json"
    $search = Invoke-RestMethod -Uri $searchUrl -TimeoutSec 20
    $hit = $search.query.search | Select-Object -First 1
    if (-not $hit) {
        Write-Warning "Nenhum artigo encontrado para '$Query'"
        return
    }
    $title = $hit.title
    $sumUrl = "https://$Lang.wikipedia.org/api/rest_v1/page/summary/$([uri]::EscapeDataString($title))"
    $sum = Invoke-RestMethod -Uri $sumUrl -TimeoutSec 20
    [pscustomobject]@{
        Title       = $sum.title
        Description = $sum.description
        Extract     = $sum.extract
        Url         = $sum.content_urls.desktop.page
        Lang        = $Lang
        QueriedAt   = (Get-Date).ToString('s')
    }
}

function Watch-ZicutakeNews {
    <#
    .SYNOPSIS
      Loop de monitoramento: reimprime manchetes a cada N segundos.
    .EXAMPLE
      Watch-ZicutakeNews -Category World -Seconds 60 -Top 5
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('World','USA','Tech','Business','Crypto','Science')]
        [string]$Category = 'World',
        [int]$Seconds = 60,
        [int]$Top = 5,
        [ValidateSet('pt','en')]
        [string]$Lang = 'pt'
    )
    Write-Host "Zicutake News Watch · $Category · a cada ${Seconds}s · Ctrl+C para sair" -ForegroundColor Cyan
    Write-Host "Web: $script:ZicutakeNewsHome" -ForegroundColor DarkGray
    while ($true) {
        Clear-Host
        Write-Host "=== ZICUTAKE NEWS LIVE $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Green
        Get-ZicutakeNews -Category $Category -Lang $Lang -Top $Top |
            Format-Table Title, Source, Published -Wrap
        Write-Host "`nPróxima atualização em ${Seconds}s…" -ForegroundColor DarkGray
        Start-Sleep -Seconds $Seconds
    }
}

function Open-ZicutakeNews {
    <#
    .SYNOPSIS
      Abre o site Zicutake News Live no navegador.
    #>
    Start-Process $script:ZicutakeNewsHome
}

Export-ModuleMember -Function @(
    'Get-ZicutakeNews',
    'Get-ZicutakeMarkets',
    'Get-ZicutakeCrypto',
    'Get-ZicutakeWiki',
    'Watch-ZicutakeNews',
    'Open-ZicutakeNews',
    'Get-ZicutakeRssUrl'
)
