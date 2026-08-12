table 80267 "TBGC Brands"
{
    Caption = 'TBGC Brands';
    DataClassification = ToBeClassified;
    LookupPageId = "TBGC Brands";
    DrillDownPageId = "TBGC Brands";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
        }

        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }

        field(3; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure".Code;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
