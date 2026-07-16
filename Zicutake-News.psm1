#Requires -Version 5.1
<#
.SYNOPSIS
  Zicutake News Live — módulo PowerShell (feeds estáveis + fallbacks)
.DESCRIPTION
  Notícias, mercados, crypto e Wikipedia no terminal.
  Autor: Joaquim Pedro de Morais Filho · Elevbit / OpS
.LINK
  https://elevbit-ai.github.io/zicutake-news/
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ZicutakeNewsHome = 'https://elevbit-ai.github.io/zicutake-news/'
$script:UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ZicutakeNews/2.0 (+https://elevbit-ai.github.io/zicutake-news/)'

function Get-ZicutakeHttp {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [int]$TimeoutSec = 35
    )
    $params = @{
        Uri             = $Uri
        UseBasicParsing = $true
        TimeoutSec      = $TimeoutSec
        Headers         = @{
            'User-Agent'      = $script:UserAgent
            'Accept'          = 'application/rss+xml, application/xml, text/xml, application/json, */*'
            'Accept-Language' = 'en-US,en;q=0.9,pt-BR;q=0.8'
        }
    }
    return Invoke-WebRequest @params
}

function Get-ZicutakeFeedCatalog {
    # Primary + fallback URLs (if first fails, next is tried)
    return @{
        World = @(
            'https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en'
            'https://feeds.bbci.co.uk/news/world/rss.xml'
            'https://rss.nytimes.com/services/xml/rss/nyt/World.xml'
            'https://www.reddit.com/r/worldnews/.rss'
        )
        USA = @(
            'https://news.google.com/rss/search?q=United+States&hl=en-US&gl=US&ceid=US:en'
            'https://feeds.bbci.co.uk/news/world/us_and_canada/rss.xml'
            'https://rss.nytimes.com/services/xml/rss/nyt/US.xml'
        )
        Tech = @(
            'https://news.google.com/rss/search?q=technology&hl=en-US&gl=US&ceid=US:en'
            'https://feeds.bbci.co.uk/news/technology/rss.xml'
            'https://www.reddit.com/r/technology/.rss'
            'https://hnrss.org/frontpage'
        )
        Business = @(
            'https://news.google.com/rss/search?q=business+OR+markets&hl=en-US&gl=US&ceid=US:en'
            'https://feeds.bbci.co.uk/news/business/rss.xml'
            'https://rss.nytimes.com/services/xml/rss/nyt/Business.xml'
        )
        Crypto = @(
            'https://news.google.com/rss/search?q=bitcoin+OR+cryptocurrency&hl=en-US&gl=US&ceid=US:en'
            'https://www.reddit.com/r/CryptoCurrency/.rss'
            'https://www.coindesk.com/arc/outboundfeeds/rss/'
        )
        Science = @(
            'https://news.google.com/rss/search?q=science&hl=en-US&gl=US&ceid=US:en'
            'https://feeds.bbci.co.uk/news/science_and_environment/rss.xml'
            'https://rss.nytimes.com/services/xml/rss/nyt/Science.xml'
        )
        Brazil = @(
            'https://news.google.com/rss?hl=pt-BR&gl=BR&ceid=BR:pt-419'
            'https://g1.globo.com/dynamo/rss2.xml'
            'https://www.reddit.com/r/brasil/.rss'
        )
    }
}

function ConvertTo-ZicutakeNewsItems {
    param(
        [Parameter(Mandatory)][string]$XmlText,
        [string]$Category = 'World',
        [int]$Top = 12
    )

    # Clean BOM / invalid control chars that break [xml]
    $clean = $XmlText -replace "^\uFEFF", ''
    $clean = $clean -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''

    try {
        [xml]$rss = $clean
    } catch {
        # Retry with XmlDocument + safer load
        $rss = New-Object System.Xml.XmlDocument
        $rss.PreserveWhitespace = $false
        $rss.XmlResolver = $null
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.DtdProcessing = [System.Xml.DtdProcessing]::Ignore
        $settings.XmlResolver = $null
        $sr = New-Object System.IO.StringReader($clean)
        $reader = [System.Xml.XmlReader]::Create($sr, $settings)
        $rss.Load($reader)
        $reader.Close()
    }

    $rawItems = @()
    if ($rss.rss -and $rss.rss.channel -and $rss.rss.channel.item) {
        $rawItems = @($rss.rss.channel.item)
    } elseif ($rss.feed -and $rss.feed.entry) {
        # Atom
        foreach ($e in @($rss.feed.entry)) {
            $link = ''
            if ($e.link.href) { $link = [string]$e.link.href }
            elseif ($e.link -is [array] -and $e.link[0].href) { $link = [string]$e.link[0].href }
            $rawItems += [pscustomobject]@{
                title   = $e.title
                link    = $link
                pubDate = $e.updated
                source  = @{ '#text' = 'Atom' }
            }
        }
    }

    $out = @()
    foreach ($it in ($rawItems | Select-Object -First $Top)) {
        $title = [string]$it.title
        if ([string]::IsNullOrWhiteSpace($title)) { continue }

        $link = [string]$it.link
        if ([string]::IsNullOrWhiteSpace($link) -and $it.guid) {
            $link = [string]$it.guid.'#text'
            if (-not $link) { $link = [string]$it.guid }
        }

        $source = 'News'
        if ($it.source) {
            if ($it.source.'#text') { $source = [string]$it.source.'#text' }
            else { $source = [string]$it.source }
        } elseif ($title -match '\s-\s([^-]+)$') {
            $source = $Matches[1].Trim()
        }

        $pub = [string]$it.pubDate
        if (-not $pub) { $pub = [string]$it.pubdate }

        $out += [pscustomobject]@{
            Title     = $title.Trim()
            Link      = $link.Trim()
            Published = $pub
            Source    = $source.Trim()
            Category  = $Category
            QueriedAt = (Get-Date).ToString('s')
            Ecosystem = 'Zicutake News Live'
        }
    }
    return $out
}

function Get-ZicutakeNews {
    <#
    .SYNOPSIS
      Manchetes em tempo real com fallbacks automáticos.
    .EXAMPLE
      Get-ZicutakeNews -Category Tech -Top 10
    .EXAMPLE
      Get-ZicutakeNews -Query "artificial intelligence"
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('World','USA','Tech','Business','Crypto','Science','Brazil')]
        [string]$Category = 'World',
        [string]$Query,
        [int]$Top = 12
    )

    $urls = @()
    if ($Query) {
        $q = [uri]::EscapeDataString($Query)
        $urls = @(
            "https://news.google.com/rss/search?q=$q&hl=en-US&gl=US&ceid=US:en"
            "https://news.google.com/rss/search?q=$q&hl=pt-BR&gl=BR&ceid=BR:pt-419"
            "https://hnrss.org/newest?q=$q"
        )
    } else {
        $catalog = Get-ZicutakeFeedCatalog
        $urls = @($catalog[$Category])
    }

    $errors = @()
    foreach ($url in $urls) {
        try {
            Write-Verbose "Trying feed: $url"
            $resp = Get-ZicutakeHttp -Uri $url
            $items = ConvertTo-ZicutakeNewsItems -XmlText $resp.Content -Category $Category -Top $Top
            if ($items -and $items.Count -gt 0) {
                Write-Verbose "OK $($items.Count) items from $url"
                return $items
            }
            $errors += "Empty feed: $url"
        } catch {
            $errors += "Fail $url -> $($_.Exception.Message)"
            Write-Verbose $errors[-1]
        }
    }

    Write-Error ("Nenhum feed respondeu. Detalhes:`n - " + ($errors -join "`n - "))
}

function Get-ZicutakeMarkets {
    [CmdletBinding()]
    param([string[]]$To = @('BRL','EUR','GBP','JPY'))
    $symbols = ($To -join ',')
    $url = "https://api.frankfurter.app/latest?from=USD&to=$symbols"
    try {
        $data = Invoke-RestMethod -Uri $url -TimeoutSec 25 -Headers @{ 'User-Agent' = $script:UserAgent }
    } catch {
        # fallback exchangerate.host style open.er-api
        $url2 = 'https://open.er-api.com/v6/latest/USD'
        $data2 = Invoke-RestMethod -Uri $url2 -TimeoutSec 25 -Headers @{ 'User-Agent' = $script:UserAgent }
        foreach ($k in $To) {
            if ($null -eq $data2.rates.$k) { continue }
            [pscustomobject]@{
                Pair = "USD/$k"; Rate = [decimal]$data2.rates.$k
                Date = $data2.time_last_update_utc; Provider = 'open.er-api'; QueriedAt = (Get-Date).ToString('s')
            }
        }
        return
    }
    foreach ($k in $data.rates.PSObject.Properties.Name) {
        [pscustomobject]@{
            Pair = "USD/$k"; Rate = [decimal]$data.rates.$k
            Date = $data.date; Provider = 'Frankfurter'; QueriedAt = (Get-Date).ToString('s')
        }
    }
}

function Get-ZicutakeCrypto {
    [CmdletBinding()]
    param([string[]]$Ids = @('bitcoin','ethereum','solana','dogecoin'))
    $idList = ($Ids -join ',')
    $url = "https://api.coingecko.com/api/v3/simple/price?ids=$idList&vs_currencies=usd,brl&include_24hr_change=true"
    try {
        $data = Invoke-RestMethod -Uri $url -TimeoutSec 25 -Headers @{ 'User-Agent' = $script:UserAgent }
    } catch {
        Write-Error "Crypto API indisponível: $($_.Exception.Message)"
        return
    }
    foreach ($id in $Ids) {
        $c = $data.$id
        if (-not $c) { continue }
        [pscustomobject]@{
            Asset = $id; USD = $c.usd; BRL = $c.brl
            Change24hPct = [math]::Round([double]$c.usd_24h_change, 2)
            Provider = 'CoinGecko'; QueriedAt = (Get-Date).ToString('s')
        }
    }
}

function Get-ZicutakeWiki {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Query,
        [ValidateSet('pt','en')][string]$Lang = 'en'
    )
    $searchUrl = "https://$Lang.wikipedia.org/w/api.php?action=query&list=search&srsearch=$([uri]::EscapeDataString($Query))&utf8=&format=json"
    $search = Invoke-RestMethod -Uri $searchUrl -TimeoutSec 25 -Headers @{ 'User-Agent' = $script:UserAgent }
    $hit = $search.query.search | Select-Object -First 1
    if (-not $hit) {
        Write-Warning "Nenhum artigo para '$Query'"
        return
    }
    $title = $hit.title
    $sumUrl = "https://$Lang.wikipedia.org/api/rest_v1/page/summary/$([uri]::EscapeDataString($title))"
    $sum = Invoke-RestMethod -Uri $sumUrl -TimeoutSec 25 -Headers @{ 'User-Agent' = $script:UserAgent }
    [pscustomobject]@{
        Title = $sum.title; Description = $sum.description; Extract = $sum.extract
        Url = $sum.content_urls.desktop.page; Lang = $Lang; QueriedAt = (Get-Date).ToString('s')
    }
}

function Watch-ZicutakeNews {
    [CmdletBinding()]
    param(
        [ValidateSet('World','USA','Tech','Business','Crypto','Science','Brazil')]
        [string]$Category = 'World',
        [int]$Seconds = 60,
        [int]$Top = 5
    )
    Write-Host "Zicutake News Watch · $Category · ${Seconds}s · Ctrl+C sai" -ForegroundColor Cyan
    Write-Host "Web: $script:ZicutakeNewsHome`n" -ForegroundColor DarkGray
    while ($true) {
        Clear-Host
        Write-Host "=== ZICUTAKE NEWS $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Green
        try {
            Get-ZicutakeNews -Category $Category -Top $Top | Format-Table Title, Source -Wrap
        } catch {
            Write-Host "Erro: $_" -ForegroundColor Red
        }
        Write-Host "`nPróxima em ${Seconds}s…" -ForegroundColor DarkGray
        Start-Sleep -Seconds $Seconds
    }
}

function Open-ZicutakeNews {
    Start-Process $script:ZicutakeNewsHome
}

function Show-ZicutakeHelp {
    @"

  ZICUTAKE NEWS LIVE — comandos
  Web: $script:ZicutakeNewsHome

  Get-ZicutakeNews -Category World|USA|Tech|Business|Crypto|Science|Brazil
  Get-ZicutakeNews -Query "inteligencia artificial" -Top 10
  Get-ZicutakeMarkets
  Get-ZicutakeCrypto
  Get-ZicutakeWiki -Query "Brazil" -Lang en
  Watch-ZicutakeNews -Category Tech -Seconds 60
  Open-ZicutakeNews

  Via CMD:
    zicutake.cmd news
    zicutake.cmd tech
    zicutake.cmd markets
    zicutake.cmd crypto
    zicutake.cmd wiki Brazil
    zicutake.cmd web
    zicutake.cmd help

"@ | Write-Host -ForegroundColor Cyan
}

Export-ModuleMember -Function @(
    'Get-ZicutakeNews','Get-ZicutakeMarkets','Get-ZicutakeCrypto',
    'Get-ZicutakeWiki','Watch-ZicutakeNews','Open-ZicutakeNews',
    'Show-ZicutakeHelp','Get-ZicutakeFeedCatalog'
)
