table 80206 "TBGC Concept Table"
{
    Caption = 'TBGC Concept Table';
    DataClassification = ToBeClassified;
    LookupPageId = "TBGC Concept List";
    DrillDownPageId = "TBGC Concept List";

    fields
    {
        field(1; "Concept Code"; Code[20])
        {
            Caption = 'Concept Code';
        }

        field(2; Description; Text[100])
        {
            Caption = 'Concept Description';
        }

        field(3; "Template Master"; Code[50])
        {
            Caption = 'Template Master';
            TableRelation = "User Setup"."User ID";
        }
    }

    keys
    {
        key(PK; "Concept Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Concept Code", Description, "Template Master") { }
    }
}
