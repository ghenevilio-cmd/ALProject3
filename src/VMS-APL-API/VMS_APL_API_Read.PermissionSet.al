permissionset 80213 "VMS APL API READ"
{
    Assignable = true;
    Caption = 'VMS APL API Read';

    Permissions =
        tabledata "Approved Product List" = RIM,
        tabledata "TBGC Zoning Table" = R,
        tabledata "TBGC Concept Table" = R,
        page "VMS APL Approved Prod. API" = X,
        page "VMS APL Zone Code API" = X,
        page "VMS APL Concept Code API" = X;
}
