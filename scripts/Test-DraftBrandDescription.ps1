$ErrorActionPreference = 'Stop'

$project = Split-Path -Parent $PSScriptRoot
$draftLine = Get-Content -Raw -LiteralPath (Join-Path $project 'src/ReactBC-main/TBGC_Draft_Order/TBGC_DraftOrderLine.Table.al')
$omsCreator = Get-Content -Raw -LiteralPath (Join-Path $project 'src/OMSAPI2/OMS2CommandMgtV2.Codeunit.al')
$marketListCreator = Get-Content -Raw -LiteralPath (Join-Path $project 'src/ReactBC-main/Code Units/TBGC_DraftOrderMgt.Codeunit.al')

$required = @(
    @($draftLine, 'trigger OnValidate()', 'Draft line Brand Code validation'),
    @($draftLine, 'BrandList.Get("Item No.", "TBGC Brand Code")', 'item/brand master-data lookup'),
    @($draftLine, '"TBGC Brand Description" := BrandList."TBGC Brand Description";', 'authoritative Brand Description assignment'),
    @($omsCreator, 'DraftLine.Validate("TBGC Brand Code", CommandLine."Brand Code");', 'OMSAPI2 validated Brand Code assignment'),
    @($marketListCreator, 'DraftOrderLine.Validate("TBGC Brand Code", BrandCode);', 'Market List validated Brand Code assignment')
)

foreach ($contract in $required) {
    if ($contract[0] -notmatch [regex]::Escape($contract[1])) {
        throw "Missing $($contract[2])."
    }
}

if ($omsCreator -match 'DraftLine\."TBGC Brand Code"\s*:=') {
    throw 'OMSAPI2 still bypasses Draft Line Brand Code validation.'
}
if ($marketListCreator -match 'DraftOrderLine\."TBGC Brand Description"\s*:=' -or
    $marketListCreator -match "LineObj\.Get\('brandDescription'") {
    throw 'Market List still trusts a caller-supplied Brand Description.'
}

Write-Output 'Draft Order brand-description contracts passed.'
