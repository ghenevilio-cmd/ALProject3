pageextension 80204 "TBGC Store List Ext" extends "LSC Store List"
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
