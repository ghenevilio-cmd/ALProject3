pageextension 80288 "TBGC LSC Pick Rcvg Pg" extends "LSC Picking/Receiving Lines"
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
