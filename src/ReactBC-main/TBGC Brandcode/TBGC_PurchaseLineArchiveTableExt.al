tableextension 80268 "TBGC Purchase Line Archive Ext" extends "Purchase Line Archive"
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
