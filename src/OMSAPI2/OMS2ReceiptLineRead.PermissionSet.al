permissionset 80261 "OMS2 RCPT LINE READ"
{
    Assignable = true;
    Caption = 'OMS/VMS Receipt Line Read';
    Permissions = tabledata "LSC Store" = R,
                  codeunit "OMS2 Receipt Store Mapping" = X,
                  tabledata "Purch. Rcpt. Header" = R,
                  tabledata "Purch. Rcpt. Line" = R,
                  page "OMS2 Posted Receipt Lines API" = X;
}
