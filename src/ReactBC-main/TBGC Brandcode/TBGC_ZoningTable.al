table 80201 "TBGC Zoning Table"
{
    Caption = 'TBGC Zoning Table';
    DataClassification = ToBeClassified;
    LookupPageId = "TBGC Zoning List";
    DrillDownPageId = "TBGC Zoning List";

    fields
    {
        field(1; "Zoning Code"; Code[20])
        {
            Caption = 'Zoning Code';
        }

        field(2; "Description"; Text[100])
        {
            Caption = 'Zoning Description';
        }
    }

    keys
    {
        key(PK; "Zoning Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Zoning Code", "Description") { }
    }
}
