page 80261 "OMS2 Posted Receipt Lines API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'Posted Receipt Line';
    EntitySetCaption = 'Posted Receipt Lines';
    EntityName = 'postedReceiptLine';
    EntitySetName = 'postedReceiptLines';
    PageType = API;
    SourceTable = "Purch. Rcpt. Line";
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;
    AboutText = 'Receipt evidence for one exact purchase order line. Requires exact orderNumber and orderLineNumber filters. Standard line Undo requires the separate service execution permission.';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(id; Rec.SystemId) { Caption = 'id'; }
                field(undoContractVersion; UndoContractVersion) { Caption = 'undoContractVersion'; }
                field(receiptId; ReceiptHeader.SystemId) { Caption = 'receiptId'; }
                field(receiptNumber; Rec."Document No.") { Caption = 'receiptNumber'; }
                field(lineNumber; Rec."Line No.") { Caption = 'lineNumber'; }
                field(orderNumber; Rec."Order No.") { Caption = 'orderNumber'; }
                field(orderLineNumber; Rec."Order Line No.") { Caption = 'orderLineNumber'; }
                field(vendorNumber; Rec."Buy-from Vendor No.") { Caption = 'vendorNumber'; }
                field(itemNumber; Rec."No.") { Caption = 'itemNumber'; }
                field(lineType; Rec.Type.AsInteger()) { Caption = 'lineType'; }
                field(locationCode; Rec."Location Code") { Caption = 'locationCode'; }
                field(conceptCode; StoreConceptCode) { Caption = 'conceptCode'; }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code") { Caption = 'shortcutDimension1Code'; }
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { Caption = 'unitOfMeasureCode'; }
                field(quantityPerUnitOfMeasure; Rec."Qty. per Unit of Measure") { Caption = 'quantityPerUnitOfMeasure'; }
                field(quantity; Rec.Quantity) { Caption = 'quantity'; }
                field(quantityBase; Rec."Quantity (Base)") { Caption = 'quantityBase'; }
                field(quantityInvoiced; Rec."Quantity Invoiced") { Caption = 'quantityInvoiced'; }
                field(quantityInvoicedBase; Rec."Qty. Invoiced (Base)") { Caption = 'quantityInvoicedBase'; }
                field(quantityReceivedNotInvoiced; Rec."Qty. Rcd. Not Invoiced") { Caption = 'quantityReceivedNotInvoiced'; }
                field(correction; Rec.Correction) { Caption = 'correction'; }
                field(salesOrderNumber; Rec."Sales Order No.") { Caption = 'salesOrderNumber'; }
                field(specialOrderSalesNumber; Rec."Special Order Sales No.") { Caption = 'specialOrderSalesNumber'; }
                field(jobNumber; Rec."Job No.") { Caption = 'jobNumber'; }
                field(productionOrder; Rec.IsProdOrder()) { Caption = 'productionOrder'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'lastModifiedDateTime'; }
            }
        }
    }

    var
        UndoContractVersion: Integer;
        StoreConceptCode: Code[20];
        ReceiptHeader: Record "Purch. Rcpt. Header";
        ExactLineRequiredErr: Label 'An exact purchase order number and order line number are required.';

    trigger OnOpenPage()
    begin
        UndoContractVersion := 2;
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
        if (Rec.GetFilter("Order No.") = '') or (Rec.GetFilter("Order Line No.") = '') then
            Error(ExactLineRequiredErr);
        if (Rec.GetRangeMin("Order No.") = '') or
           (Rec.GetRangeMin("Order No.") <> Rec.GetRangeMax("Order No.")) or
           (Rec.GetRangeMin("Order Line No.") <= 0) or
           (Rec.GetRangeMin("Order Line No.") <> Rec.GetRangeMax("Order Line No.")) then
            Error(ExactLineRequiredErr);
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure Undo(var ActionContext: WebServiceActionContext; RequestId: Guid; ExpectedCompanyId: Guid; ExpectedReceiptId: Guid; ExpectedReceiptLineNumber: Integer;
        ExpectedOrderNumber: Code[20]; ExpectedOrderLineNumber: Integer; ExpectedVendorNumber: Code[20];
        ExpectedItemNumber: Code[20]; ExpectedLocationCode: Code[10]; ExpectedConceptCode: Code[20];
        ExpectedUnitOfMeasureCode: Code[10]; ExpectedQuantity: Decimal; ExpectedQuantityBase: Decimal; ExpectedModifiedAt: DateTime)
    begin
        Error('This receipt Undo contract is retired. Refresh through the updated OMS connector.');
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure UndoV2(var ActionContext: WebServiceActionContext; RequestId: Guid; ExpectedCompanyId: Guid; ExpectedReceiptId: Guid; ExpectedReceiptLineNumber: Integer;
        ExpectedOrderNumber: Code[20]; ExpectedOrderLineNumber: Integer; ExpectedVendorNumber: Code[20];
        ExpectedItemNumber: Code[20]; ExpectedLocationCode: Code[10]; ExpectedConceptCode: Code[20]; ExpectedShortcutDimension1Code: Code[20];
        ExpectedUnitOfMeasureCode: Code[10]; ExpectedQuantity: Decimal; ExpectedQuantityBase: Decimal; ExpectedModifiedAt: DateTime)
    var
        ReceiptUndo: Codeunit "OMS2 Receipt Line Undo";
        CorrectionId: Guid;
    begin
        CorrectionId := ReceiptUndo.Execute(Rec.SystemId, RequestId, ExpectedCompanyId, ExpectedReceiptId, ExpectedReceiptLineNumber, ExpectedOrderNumber,
            ExpectedOrderLineNumber, ExpectedVendorNumber, ExpectedItemNumber, ExpectedLocationCode, ExpectedConceptCode, ExpectedShortcutDimension1Code,
            ExpectedUnitOfMeasureCode, ExpectedQuantity, ExpectedQuantityBase, ExpectedModifiedAt);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"OMS2 Posted Receipt Lines API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), CorrectionId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Created);
    end;

    trigger OnAfterGetRecord()
    var
        Store: Record "LSC Store";
        Mapping: Codeunit "OMS2 Receipt Store Mapping";
    begin
        Clear(StoreConceptCode);
        StoreConceptCode := Mapping.ResolveConcept(Store, Rec."Location Code", false);
        // A missing parent is an integrity failure, never an empty receipt identity.
        if ReceiptHeader."No." <> Rec."Document No." then begin
            ReceiptHeader.SetLoadFields(SystemId);
            ReceiptHeader.Get(Rec."Document No.");
        end;
    end;
}
