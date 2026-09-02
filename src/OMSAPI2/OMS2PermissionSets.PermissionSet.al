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
        tabledata "TBGC Concept Table" = R,
        tabledata "TBGC Zoning Table" = R,
        tabledata "LSC Store" = R,
        tabledata "Approved Product List" = R,
        tabledata "OMS2 Receipt Command" = RIM,
        tabledata "OMS2 Receipt Command Line" = RIMD,
        page "OMS2 Purchase Orders API" = X,
        page "OMS2 Purchase Order Lines API" = X,
        page "OMS2 Purchase Receipts API" = X,
        page "OMS2 Receipt Commands API" = X,
        page "OMS2 Receipt Command Lines API" = X,
        page "OMS2 Concepts API" = X,
        page "OMS2 Stores API" = X,
        page "OMS2 Zoning API" = X,
        page "OMS2 Approved Products API" = X,
        codeunit "OMS2 Command Mgt" = X,
        codeunit "Release Purchase Document" = X,
        codeunit "Purch.-Post" = X;
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
        tabledata "OMS2 Receipt Command" = R,
        tabledata "OMS2 Receipt Command Line" = R,
        tabledata "TBGC Concept Table" = R,
        tabledata "TBGC Zoning Table" = R,
        tabledata "LSC Store" = R,
        tabledata "Approved Product List" = R,
        tabledata Vendor = R,
        tabledata Item = R,
        page "OMS2 Purchase Orders API" = X,
        page "OMS2 Purchase Order Lines API" = X,
        page "OMS2 Purchase Receipts API" = X,
        page "OMS2 Receipt Commands API" = X,
        page "OMS2 Receipt Command Lines API" = X,
        page "OMS2 Concepts API" = X,
        page "OMS2 Stores API" = X,
        page "OMS2 Zoning API" = X,
        page "OMS2 Approved Products API" = X;
}
