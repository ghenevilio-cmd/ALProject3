tableextension 80270 "TBGC Purch Inv Line Ext" extends "Purch. Inv. Line"
{
    fields
    {
        field(80251; "TBGC Brand Code"; Code[20])
        {
            Caption = 'TBGC Brand Code';
            DataClassification = ToBeClassified;
        }
    }
}
