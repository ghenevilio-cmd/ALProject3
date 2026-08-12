pageextension 80299 "TBGC User Setup APL Activation" extends "User Setup"
{
    layout
    {
        addbefore("Allow PO Creation")
        {
            field("TBGC Allowed APL Activation"; Rec."TBGC Allowed APL Activation")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the user can reactivate inactive Approved Product List lines.';
            }
        }
    }
}
