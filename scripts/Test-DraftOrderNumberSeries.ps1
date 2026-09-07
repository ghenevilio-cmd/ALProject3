$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot

function Read-ProjectFile([string]$relativePath) {
    Get-Content -LiteralPath (Join-Path $projectRoot $relativePath) -Raw
}

function Assert-Match([string]$content, [string]$pattern, [string]$message) {
    if ($content -notmatch $pattern) {
        throw $message
    }
}

$setupTable = Read-ProjectFile 'src\ReactBC-main\Purchase & Payables Extension\APL_PurchPayablesSetup.TableExt.al'
$setupPage = Read-ProjectFile 'src\ReactBC-main\Purchase & Payables Extension\APL_PurchPayablesSetup.PageExt.al'
$draftHeader = Read-ProjectFile 'src\ReactBC-main\TBGC_Draft_Order\TBGC_DraftOrderHeader.Table.al'
$apiPermissions = Read-ProjectFile 'src\OMSAPI2\OMS2PermissionSets.PermissionSet.al'
$converter = Read-ProjectFile 'src\ReactBC-main\Code Units\TBGC_DraftOrderConverter.Codeunit.al'

Assert-Match $setupTable 'field\(80292;\s*"TBGC Draft Order Nos\.";\s*Code\[20\]\)' 'Missing TBGC Draft Order Nos. setup field.'
Assert-Match $setupPage 'addlast\("Number Series"\)' 'Missing TBGC Draft Order Nos. field in the Number Series setup group.'
Assert-Match $draftHeader 'field\(14;\s*"No\. Series";\s*Code\[20\]\)' 'Missing source No. Series on Draft Order Header.'
Assert-Match $draftHeader 'NoSeries\.GetNextNo\("No\. Series"\)' 'Draft Order Header does not use the native No. Series allocator.'
if ($draftHeader -match 'GetNextDraftNo|DRF-') {
    throw 'Hardcoded Draft Order numbering remains in Draft Order Header.'
}
Assert-Match $apiPermissions 'tabledata\s+"Purchases & Payables Setup"\s*=\s*R' 'OMS2 API WRITE cannot read Purchases & Payables Setup.'
if ($converter -match 'TBGC Draft Order Nos\.') {
    throw 'Draft-to-PO conversion must not depend on current numbering setup.'
}

Write-Output 'Draft Order Number Series contract passed.'
