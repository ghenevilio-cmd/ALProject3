pageextension 80205 "TBGC Store Card Ext" extends "LSC Store Card"
{
    layout
    {
        addafter("Location Code")
        {
            field("TBGC Zoning Code"; Rec."TBGC Zoning Code")
            {
                ApplicationArea = All;
                Caption = 'Zoning Code';
            }
            field("TBGC Concept Code"; Rec."TBGC Concept Code")
            {
                ApplicationArea = All;
                Caption = 'Concept Code';
            }
        }
    }
}
