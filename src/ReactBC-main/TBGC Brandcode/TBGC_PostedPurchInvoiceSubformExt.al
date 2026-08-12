pageextension 80274 "TBGC Posted Purch Inv Subf" extends "Posted Purch. Invoice Subform"
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
