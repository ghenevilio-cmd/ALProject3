table 80264 "TBGC Brand List"
{
    Caption = 'TBGC Brand List';
    DataClassification = ToBeClassified;
    LookupPageId = "TBGC Brand List";
    DrillDownPageId = "TBGC Brand List";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                CheckDuplicateBrandList();
            end;
        }

        field(2; "TBGC Brand Code"; Code[20])
        {
            Caption = 'TBGC Brand Code';
            TableRelation = "TBGC Brands".Code;

            trigger OnValidate()
            var
                TBGCBrands: Record "TBGC Brands";
            begin
                if "TBGC Brand Code" = '' then begin
                    "TBGC Brand Description" := '';
                    "Unit of Measure Code" := '';
                    exit;
                end;

                if TBGCBrands.Get("TBGC Brand Code") then begin
                    "TBGC Brand Description" := TBGCBrands.Description;

                    if TBGCBrands."Unit of Measure Code" <> '' then begin
                        ValidateItemUnitOfMeasure(TBGCBrands."Unit of Measure Code");
                        "Unit of Measure Code" := TBGCBrands."Unit of Measure Code";
                    end else
                        "Unit of Measure Code" := '';
                end else begin
                    "TBGC Brand Description" := '';
                    "Unit of Measure Code" := '';
                end;

                CheckDuplicateBrandList();
            end;
        }

        field(3; "TBGC Brand Description"; Text[100])
        {
            Caption = 'TBGC Brand Description';
            Editable = false;
        }

        field(4; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
    }

    keys
    {
        key(PK; "Item No.", "TBGC Brand Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        CheckDuplicateBrandList();
    end;

    trigger OnModify()
    begin
        CheckDuplicateBrandList();
    end;

    local procedure ValidateItemUnitOfMeasure(UnitOfMeasureCode: Code[10])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if ("Item No." = '') or (UnitOfMeasureCode = '') then
            exit;

        ItemUnitOfMeasure.SetRange("Item No.", "Item No.");
        ItemUnitOfMeasure.SetRange(Code, UnitOfMeasureCode);
        if ItemUnitOfMeasure.IsEmpty() then
            Error(
              'Unit of Measure Code %1 is not set up for Item No. %2.',
              UnitOfMeasureCode,
              "Item No.");
    end;

    local procedure CheckDuplicateBrandList()
    var
        ExistingBrandList: Record "TBGC Brand List";
        DuplicateBrandListErr: Label 'The combination of Item No. %1 and TBGC Brand Code %2 already exists.';
    begin
        if ("Item No." = '') or ("TBGC Brand Code" = '') then
            exit;

        ExistingBrandList.SetRange("Item No.", "Item No.");
        ExistingBrandList.SetRange("TBGC Brand Code", "TBGC Brand Code");

        if ExistingBrandList.FindFirst() then
            if (ExistingBrandList."Item No." <> xRec."Item No.") or
               (ExistingBrandList."TBGC Brand Code" <> xRec."TBGC Brand Code")
            then
                Error(DuplicateBrandListErr, "Item No.", "TBGC Brand Code");
    end;
}
