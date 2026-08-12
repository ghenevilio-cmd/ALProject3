tableextension 80284 "TBGC Item Vendor Ext" extends "Item Vendor"
{
    fields
    {
        field(80251; "TBGC Brand Code"; Code[20])
        {
            Caption = 'TBGC Brand Code';
            DataClassification = ToBeClassified;
            TableRelation = "TBGC Brands".Code;
        }
    }
}
