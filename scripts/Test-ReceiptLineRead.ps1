$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$page = Get-Content -Raw -LiteralPath (Join-Path $root 'src/OMSAPI2/OMS2PostedReceiptLines.Api.Page.al')
$permission = Get-Content -Raw -LiteralPath (Join-Path $root 'src/OMSAPI2/OMS2ReceiptLineRead.PermissionSet.al')
foreach ($required in @('InsertAllowed = false;', 'ModifyAllowed = false;', 'DeleteAllowed = false;', 'Editable = false;', 'ODataKeyFields = SystemId;', 'GetRangeMin("Order No.")', 'GetRangeMax("Order No.")', 'GetRangeMin("Order Line No.")', 'GetRangeMax("Order Line No.")', 'ReceiptHeader.Get(Rec."Document No.")', 'field(quantityInvoiced;', 'field(quantityInvoicedBase;', 'field(correction;')) {
 if (-not $page.Contains($required)) { throw "Missing read boundary: $required" }
}
if ($page -match '\[ServiceEnabled\]' -or $page -match '\b(Insert|Modify|Delete|Run)\(') { throw 'Read API must not expose a mutation/action' }
if ($permission -notmatch 'tabledata "Purch. Rcpt. Line" = R' -or $permission -notmatch 'tabledata "Purch. Rcpt. Header" = R' -or $permission -match '= [RIMD]*[IMD][RIMD]*[,;]' -or $permission -match 'codeunit') { throw 'Read permission widened' }
Write-Output 'Read-only AL source boundaries passed; runtime permissions and filtering remain unverified.'
