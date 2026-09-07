$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$converterPath = Join-Path $projectRoot 'src\ReactBC-main\Code Units\TBGC_DraftOrderConverter.Codeunit.al'
$converter = Get-Content -LiteralPath $converterPath -Raw

function Assert-Match([string]$content, [string]$pattern, [string]$message) {
    if ($content -notmatch $pattern) {
        throw $message
    }
}

Assert-Match $converter 'ValidateOmsCurrencyMatchesVendor' 'Draft conversion does not compare OMS currency with the vendor-derived BC currency.'
Assert-Match $converter 'General Ledger Setup' 'Draft conversion does not resolve blank BC currency through the company LCY setup.'
Assert-Match $converter 'if PurchHeader\."Currency Code" = ''''' 'Draft conversion does not treat blank Purchase Header Currency Code as local currency.'
Assert-Match $converter 'Currency Factor' 'Draft conversion no longer validates the factor for genuine foreign-currency orders.'

if ($converter -match 'PurchHeader\.Validate\("Currency Code", DraftOrderHeader\."OMS Currency Code"\)') {
    throw 'The real Purchase Header still overwrites the vendor-derived currency with the OMS currency.'
}

if ($converter -match 'TempPurchHeader\.Validate\("Currency Code", CurrencyCode\)') {
    throw 'Temporary prevalidation still overwrites the vendor-derived currency with the OMS currency.'
}

Write-Output 'Draft Order currency contract passed.'
