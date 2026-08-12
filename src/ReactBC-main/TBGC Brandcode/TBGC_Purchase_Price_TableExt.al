tableextension 80260 "TBGC Purchase Price Ext" extends "Purchase Price"
{
    fields
    {
        field(80251; "TBGC Brand Code"; Code[20])
        {
            Caption = 'TBGC Brand Code';
            DataClassification = ToBeClassified;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the custom Approved Product List.';
            ObsoleteTag = '1.0.0.4';
            TableRelation = "TBGC Brand List"."TBGC Brand Code"
                WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                BrandList: Record "TBGC Brand List";
            begin
                if "TBGC Brand Code" = '' then begin
                    "TBGC Brand Description" := '';
                    exit;
                end;

                BrandList.Reset();
                BrandList.SetRange("Item No.", "Item No.");
                BrandList.SetRange("TBGC Brand Code", "TBGC Brand Code");

                if BrandList.FindFirst() then
                    "TBGC Brand Description" := BrandList."TBGC Brand Description"
                else
                    "TBGC Brand Description" := '';
            end;
        }

        field(80252; "TBGC Brand Description"; Text[100])
        {
            Caption = 'TBGC Brand Description';
            DataClassification = ToBeClassified;
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the custom Approved Product List.';
            ObsoleteTag = '1.0.0.4';
        }

        field(80253; "Inactive"; Boolean)
        {
            Caption = 'Inactive';
            DataClassification = ToBeClassified;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the custom Approved Product List.';
            ObsoleteTag = '1.0.0.4';
            ToolTip = 'Indicates whether the purchase price record is active. Inactive records will not be used for purchasing transactions.';
        }

        field(80254; "TBGC Zoning Code"; Code[20])
        {
            Caption = 'Zoning Code';
            DataClassification = ToBeClassified;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the custom Approved Product List.';
            ObsoleteTag = '1.0.0.4';
            TableRelation = "TBGC Zoning Table"."Zoning Code";
        }
        field(80255; "TBGC Concept Code"; Code[20])
        {
            Caption = 'Concept Code';
            DataClassification = ToBeClassified;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the custom Approved Product List.';
            ObsoleteTag = '1.0.0.4';
            TableRelation = "TBGC Concept Table"."Concept Code";
        }
    }
}
