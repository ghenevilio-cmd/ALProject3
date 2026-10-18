$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$table = Get-Content -Raw -LiteralPath (Join-Path $project 'src/ReactBC-main/TBGC Brandcode/TBGC_Approved_Product_List_Table.al')
if ($table -match 'Inactive := "Ending Date" <> 0D;') { throw 'Future ending date still immediately deactivates the price.' }
foreach ($method in @('procedure SetValidOnDate(', 'procedure IsValidOnDate(')) {
    if (-not $table.Contains($method)) { throw "Missing shared date rule: $method" }
}
$consumers = @(
 'src/ReactBC-main/POS PAGE/POSPage.al',
 'src/ReactBC-main/TBGC Brandcode/TBGC_BrandSelectionMgt.Codeunit.al',
 'src/ReactBC-main/TBGC Brandcode/TBGC_FilteredBrandLookup.Page.al',
 'src/ReactBC-main/TBGC Brandcode/TBGC_PurchaseLineTableExt.al',
 'src/ReactBC-main/TBGC_Order_History/APL_OrderHistoryMgt.Codeunit.al',
 'src/ReactBC-main/TBGC_Draft_Order/TBGC_DraftPriceUpdateMgt.Codeunit.al',
 'src/APL Request Page/APL Request Page.al'
)
foreach ($source in $consumers) {
 $text = Get-Content -Raw -LiteralPath (Join-Path $project $source)
 if (-not $text.Contains('SetValidOnDate(Today)')) { throw "Current-price selector lacks date scope: $source" }
 if ($text -match 'SetRange\("?Inactive"?, false\)' -or $text -match 'SetRange\("Ending Date", 0D\)') { throw "Legacy active-only selector remains: $source" }
}
Write-Output 'APL source contracts passed. This does not execute AL runtime tests.'
