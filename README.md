# Zicutake News Live

**Sistema de notícias em tempo real** do ecossistema **Zicutake** · Elevbit / OpS  
**Autor:** Joaquim Pedro de Morais Filho

## Página online

### https://elevbit-ai.github.io/zicutake-news/

## O que inclui

| Módulo | Função |
|--------|--------|
| **Feed ao vivo** | Google News RSS (Mundo, EUA, Tech, Economia, Crypto, Ciência) |
| **Mercados** | Câmbio USD (Frankfurter API) |
| **Crypto** | BTC, ETH, SOL, DOGE (CoinGecko) |
| **Wikipedia** | Busca e resumo (PT/EN) |
| **Tendências** | Atalhos de busca |
| **PowerShell IA** | Módulo `Zicutake-News.psm1` no terminal |
| **Auto-refresh** | Atualiza a cada 90 segundos |

## PowerShell (comandos de IA / automação)

```powershell
Import-Module .\Zicutake-News.psm1

Get-ZicutakeNews -Category World
Get-ZicutakeNews -Category Tech -Top 10
Get-ZicutakeNews -Query "inteligência artificial"
Get-ZicutakeMarkets
Get-ZicutakeCrypto
Get-ZicutakeWiki -Query "Brasil"
Watch-ZicutakeNews -Seconds 60
Open-ZicutakeNews
```

## Arquivos

- `index.html` — app web (GitHub Pages)
- `Zicutake-News.psm1` — módulo PowerShell
- `demo-news.ps1` — demo rápida no terminal

## Ecossistema

- [Portfólio](https://elevbit-ai.github.io/)
- [Zicutake Browser](https://github.com/elevbit-ai/zicutake-browser)
- [USAcomment.com](https://www.usacomment.com/)
- [02.quest](https://02.quest)
- [GitHub elevbit-ai](https://github.com/elevbit-ai)

## Licença

© 2026 Joaquim Pedro de Morais Filho · Zicutake · Elevbit / OpS  
Todos os direitos reservados, salvo indicação em contrário.
