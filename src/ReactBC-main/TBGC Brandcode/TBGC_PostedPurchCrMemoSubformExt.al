pageextension 80280 "TBGC Posted Purch CrMemo" extends "Posted Purch. Cr. Memo Subform"
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
