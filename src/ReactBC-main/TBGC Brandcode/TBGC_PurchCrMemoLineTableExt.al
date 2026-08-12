tableextension 80277 "TBGC Purch Cr Memo Line" extends "Purch. Cr. Memo Line"
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
