pageextension 80272 "TBGC Purch Order Archive Subf" extends "Purchase Order Archive Subform"
{
    layout
    {
        addbefore(Description)
        {
            field("TBGC Brand Code"; Rec."TBGC Brand Code")
            {
                ApplicationArea = All;
            }
        }
    }
}
