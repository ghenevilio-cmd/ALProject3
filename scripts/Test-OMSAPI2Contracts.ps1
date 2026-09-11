$ErrorActionPreference = 'Stop'

$project = Split-Path -Parent $PSScriptRoot
$sources = @(
    'src/OMSAPI2/OMS2DraftCommand.Table.al',
    'src/OMSAPI2/OMS2DraftCommandLine.Table.al',
    'src/OMSAPI2/OMS2DraftCommandsV2.Api.Page.al',
    'src/OMSAPI2/OMS2DraftCommandLinesV2.Api.Page.al',
    'src/OMSAPI2/OMS2ReceiptCommandV2.Table.al',
    'src/OMSAPI2/OMS2ReceiptCommandLineV2.Table.al',
    'src/OMSAPI2/OMS2ReceiptCommandsV2.Api.Page.al',
    'src/OMSAPI2/OMS2ReceiptCommandLinesV2.Api.Page.al',
    'src/OMSAPI2/OMS2CommandMgtV2.Codeunit.al'
)

foreach ($source in $sources) {
    if (-not (Test-Path -LiteralPath (Join-Path $project $source))) {
        throw "Missing OMSAPI2 v2 source: $source"
    }
}

$v2 = ($sources | ForEach-Object { Get-Content -Raw -LiteralPath (Join-Path $project $_) }) -join "`n"
foreach ($required in @('commandId', 'createdByUserId', 'Payload Hash', 'Draft Order No.', 'Posted Receipt No.', 'SetSuppressCommit(true)')) {
    if ($v2 -notmatch [regex]::Escape($required)) {
        throw "OMSAPI2 v2 contract is missing: $required"
    }
}
$commandMgt = Get-Content -Raw -LiteralPath (Join-Path $project 'src/OMSAPI2/OMS2CommandMgtV2.Codeunit.al')
if ($commandMgt -notmatch 'DraftHeader\."Created By User ID"\s*:=\s*Command\."Created By User ID"') {
    throw 'OMSAPI2 v2 does not carry the command origin to the Draft Order.'
}
if ($v2 -match 'OMS PO Ref\. No\.|OMS Receiving Ref\. No\.') {
    throw 'OMSAPI2 v2 still exposes an OMS document reference.'
}

foreach ($page in @(
    'src/OMSAPI2/OMS2DraftOrderPages.PageExt.al',
    'src/OMSAPI2/OMS2PurchaseOrderCard.PageExt.al',
    'src/OMSAPI2/OMS2PurchaseOrderList.PageExt.al',
    'src/OMSAPI2/OMS2PostedPurchReceipt.PageExt.al',
    'src/OMSAPI2/OMS2PostedPurchReceipts.PageExt.al'
)) {
    if ((Get-Content -Raw -LiteralPath (Join-Path $project $page)) -match 'OMS (?:PO|Receiving) Ref\. No\.') {
        throw "Retired OMS document reference remains visible in $page"
    }
}

Write-Output 'OMSAPI2 v2 source contracts passed.'
