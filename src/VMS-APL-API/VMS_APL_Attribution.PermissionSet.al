permissionset 80268 "VMS APL ATTR WRITE"
{
    Assignable = true;
    Caption = 'VMS APL Attribution Service';
    Permissions = tabledata "VMS APL Attribution Setup" = R,
                  codeunit "VMS APL Attribution Guard" = X,
                  codeunit "VMS APL Attribution Scope" = X;
}

permissionset 80269 "VMS APL ATTR ADMIN"
{
    Assignable = true;
    Caption = 'VMS APL Attribution Setup';
    Permissions = tabledata "VMS APL Attribution Setup" = RIMD,
                  table "VMS APL Attribution Setup" = X,
                  page "VMS APL Attribution Setup" = X,
                  tabledata User = R;
}
