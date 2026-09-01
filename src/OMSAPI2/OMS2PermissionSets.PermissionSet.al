permissionset 80233 "OMS2 API WRITE"
{
    Assignable = true;
    Caption = 'OMS2 API Write';

    Permissions =
        tabledata "Purchase Header" = RIM,
        tabledata "Purchase Line" = RIM,
        tabledata "Purch. Rcpt. Header" = R,
        tabledata "Purch. Rcpt. Line" = R,
        tabledata Vendor = R,
        tabledata Item = R,
        tabledata Location = R,
        tabledata "Item Unit of Measure" = R,
        tabledata "Unit of Measure" = R,
        tabledata "Payment Terms" = R,
        tabledata "Shipment Method" = R,
        tabledata Currency = R,
        tabledata "Dimension Value" = R,
        page "OMS2 Purchase Orders API" = X,
        page "OMS2 Purchase Order Lines API" = X,
        page "OMS2 Purchase Receipts API" = X,
        codeunit "Release Purchase Document" = X;
}

permissionset 80234 "OMS2 API READ"
{
    Assignable = true;
    Caption = 'OMS2 API Read';

    Permissions =
        tabledata "Purchase Header" = R,
        tabledata "Purchase Line" = R,
        tabledata "Purch. Rcpt. Header" = R,
        tabledata "Purch. Rcpt. Line" = R,
        page "OMS2 Purchase Orders API" = X,
        page "OMS2 Purchase Order Lines API" = X,
        page "OMS2 Purchase Receipts API" = X;
}
