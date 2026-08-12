pageextension 80298 "TBGC User Setup ML Del/Edit" extends "User Setup"
{
    layout
    {
        addbefore("Allow PO Creation")
        {
            field("TBGC ML Del Edit"; Rec."TBGC ML Del Edit")
            {
                ApplicationArea = All;
            }
        }
    }
}
