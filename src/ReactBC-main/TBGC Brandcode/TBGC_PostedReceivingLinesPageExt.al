pageextension 80289 "TBGC LSC Pstd Rcvg Pg" extends "LSC Posted Receiving lines"
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
