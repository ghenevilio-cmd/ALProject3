page 80232 "OMS2 Purchase Order Lines API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Purchase Order Line';
    EntitySetCaption = 'OMS Purchase Order Lines';
    EntityName = 'purchaseOrderLine';
    EntitySetName = 'purchaseOrderLines';
    PageType = API;
    SourceTable = "Purchase Line";
    SourceTableView = where("Document Type" = const(Order), Type = const(Item));
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Creates item lines on OMS purchase orders through standard Business Central validation.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(documentNumber; Rec."Document No.")
                {
                    Caption = 'Document Number';
                    Editable = false;
                }
                field(lineNumber; LineNumber)
                {
                    Caption = 'Line Number';
                }
                field(itemNumber; ItemNumber)
                {
                    Caption = 'Item Number';
                }
                field(brandCode; BrandCode)
                {
                    Caption = 'Brand Code';
                }
                field(unitOfMeasureCode; UnitOfMeasureCode)
                {
                    Caption = 'Unit of Measure Code';
                }
                field(quantity; Quantity)
                {
                    Caption = 'Quantity';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                }
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                    Editable = false;
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Line Amount';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LineNumber := Rec."Line No.";
        ItemNumber := Rec."No.";
        BrandCode := Rec."TBGC Brand Code";
        UnitOfMeasureCode := Rec."Unit of Measure Code";
        Quantity := Rec.Quantity;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        ExistingPurchaseLine: Record "Purchase Line";
        LastPurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."Document No.");
        if ItemNumber = '' then
            Error(ItemNumberRequiredErr);
        if Quantity <= 0 then
            Error(QuantityRequiredErr);

        if LineNumber <> 0 then begin
            ExistingPurchaseLine.SetRange("Document Type", ExistingPurchaseLine."Document Type"::Order);
            ExistingPurchaseLine.SetRange("Document No.", Rec."Document No.");
            ExistingPurchaseLine.SetRange("Line No.", LineNumber);
            if ExistingPurchaseLine.FindFirst() then begin
                if (ExistingPurchaseLine."No." <> ItemNumber)
                    or (ExistingPurchaseLine."Unit of Measure Code" <> UnitOfMeasureCode)
                    or (ExistingPurchaseLine.Quantity <> Quantity)
                then
                    Error(ChangedReplayErr, LineNumber);
                // A failed deep insert can leave BC's idempotent header and line in place. Repair fields that
                // are determined by that same immutable request, then let the retry continue to Release.
                if (ExistingPurchaseLine."Location Code" <> PurchaseHeader."Location Code")
                    or (ExistingPurchaseLine."Shortcut Dimension 1 Code" <> PurchaseHeader."Location Code")
                    or ((BrandCode <> '') and (ExistingPurchaseLine."TBGC Brand Code" <> BrandCode))
                then begin
                    PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
                    ExistingPurchaseLine.Validate("Location Code", PurchaseHeader."Location Code");
                    if BrandCode <> '' then
                        ExistingPurchaseLine.Validate("TBGC Brand Code", BrandCode);
                    ExistingPurchaseLine.Validate("Shortcut Dimension 1 Code", PurchaseHeader."Location Code");
                    ExistingPurchaseLine.Modify(true);
                end;
                Rec := ExistingPurchaseLine;
                exit(false);
            end;
        end;

        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);

        Rec."Document Type" := Rec."Document Type"::Order;
        Rec.Type := Rec.Type::Item;
        if LineNumber = 0 then begin
            LastPurchaseLine.SetRange("Document Type", Rec."Document Type");
            LastPurchaseLine.SetRange("Document No.", Rec."Document No.");
            if LastPurchaseLine.FindLast() then
                LineNumber := LastPurchaseLine."Line No." + 10000
            else
                LineNumber := 10000;
        end;
        Rec."Line No." := LineNumber;
        Rec.Validate("No.", ItemNumber);
        Rec.Validate("Location Code", PurchaseHeader."Location Code");
        if BrandCode <> '' then
            Rec.Validate("TBGC Brand Code", BrandCode);
        if UnitOfMeasureCode <> '' then
            Rec.Validate("Unit of Measure Code", UnitOfMeasureCode);
        Rec.Validate(Quantity, Quantity);
        // Last, so nothing above can replace it: the line carries the same Shortcut Dimension 1 as the header,
        // which is the location. Validating "No." sets the item's default dimensions, and this is the OMS rule
        // about where the order is going rather than what is on it.
        if Rec."Shortcut Dimension 1 Code" <> PurchaseHeader."Location Code" then
            Rec.Validate("Shortcut Dimension 1 Code", PurchaseHeader."Location Code");
        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(LineNumber);
        Clear(ItemNumber);
        Clear(BrandCode);
        Clear(UnitOfMeasureCode);
        Clear(Quantity);
        Rec."Document Type" := Rec."Document Type"::Order;
        Rec.Type := Rec.Type::Item;
    end;

    var
        LineNumber: Integer;
        ItemNumber: Code[20];
        BrandCode: Code[20];
        UnitOfMeasureCode: Code[10];
        Quantity: Decimal;
        ItemNumberRequiredErr: Label 'Item Number is required.';
        QuantityRequiredErr: Label 'Quantity must be greater than zero.';
        ChangedReplayErr: Label 'Purchase order line %1 was already used with different values.';
}
