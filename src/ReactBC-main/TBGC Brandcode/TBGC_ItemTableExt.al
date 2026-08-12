tableextension 80282 "TBGC Item Ext" extends Item
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
