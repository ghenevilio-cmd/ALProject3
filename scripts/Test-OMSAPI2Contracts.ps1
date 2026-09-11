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

# Five page extensions used to be read here to prove they no longer displayed a retired OMS reference. They were
# emptied when those references came off the user interface, leaving objects that extended a page and did
# nothing, and were then removed. Reading files that no longer exist made this script fail without proving
# anything; the check above already asserts that no v2 source exposes a retired reference.

Write-Output 'OMSAPI2 v2 source contracts passed.'
