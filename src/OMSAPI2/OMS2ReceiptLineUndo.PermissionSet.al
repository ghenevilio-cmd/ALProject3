permissionset 80262 "OMS2 RCPT LINE UNDO"
{
    Assignable = true;
    Caption = 'OMS Receipt Line Undo Service';
    IncludedPermissionSets = "OMS2 RCPT LINE READ";
    Permissions = codeunit "OMS2 Receipt Line Undo" = X,
                  codeunit "Undo Purchase Receipt Line" = X,
                  tabledata Company = R,
                  tabledata Item = R,
                  tabledata Location = R,
                  tabledata "Posted Whse. Receipt Line" = R;
}
