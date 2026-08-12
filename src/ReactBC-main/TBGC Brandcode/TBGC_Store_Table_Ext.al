tableextension 80203 "TBGC Store Ext" extends "LSC Store"
{
    fields
    {
        field(80270; "TBGC Zoning Code"; Code[20])
        {
            Caption = 'Zoning Code';
            DataClassification = ToBeClassified;

            TableRelation = "TBGC Zoning Table"."Zoning Code";

            trigger OnValidate()
            var
                Zoning: Record "TBGC Zoning Table";
            begin
                if "TBGC Zoning Code" = '' then
                    exit;

                if Zoning.Get("TBGC Zoning Code") then;
            end;
        }
        field(80271; "TBGC Concept Code"; Code[20])
        {
            Caption = 'Concept Code';
            DataClassification = ToBeClassified;
            TableRelation = "TBGC Concept Table"."Concept Code";

            trigger OnValidate()
            var
                Concept: Record "TBGC Concept Table";
            begin
                if "TBGC Concept Code" = '' then
                    exit;

                if Concept.Get("TBGC Concept Code") then;
            end;
        }
    }
}
