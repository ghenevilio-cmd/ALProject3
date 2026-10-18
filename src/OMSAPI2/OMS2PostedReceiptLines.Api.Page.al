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
    AboutText = 'Read-only evidence for one exact purchase order line across its posted receipts. Requires exact orderNumber and orderLineNumber filters. Does not authorize or execute Undo.';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(id; Rec.SystemId) { Caption = 'id'; }
                field(receiptId; ReceiptHeader.SystemId) { Caption = 'receiptId'; }
                field(receiptNumber; Rec."Document No.") { Caption = 'receiptNumber'; }
                field(lineNumber; Rec."Line No.") { Caption = 'lineNumber'; }
                field(orderNumber; Rec."Order No.") { Caption = 'orderNumber'; }
                field(orderLineNumber; Rec."Order Line No.") { Caption = 'orderLineNumber'; }
                field(vendorNumber; Rec."Buy-from Vendor No.") { Caption = 'vendorNumber'; }
                field(itemNumber; Rec."No.") { Caption = 'itemNumber'; }
                field(lineType; Rec.Type.AsInteger()) { Caption = 'lineType'; }
                field(locationCode; Rec."Location Code") { Caption = 'locationCode'; }
                field(conceptCode; Rec."Shortcut Dimension 1 Code") { Caption = 'conceptCode'; }
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
        ReceiptHeader: Record "Purch. Rcpt. Header";
        ExactLineRequiredErr: Label 'An exact purchase order number and order line number are required.';

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
        if (Rec.GetFilter("Order No.") = '') or (Rec.GetFilter("Order Line No.") = '') then
            Error(ExactLineRequiredErr);
        if (Rec.GetRangeMin("Order No.") = '') or
           (Rec.GetRangeMin("Order No.") <> Rec.GetRangeMax("Order No.")) or
           (Rec.GetRangeMin("Order Line No.") <= 0) or
           (Rec.GetRangeMin("Order Line No.") <> Rec.GetRangeMax("Order Line No.")) then
            Error(ExactLineRequiredErr);
    end;

    trigger OnAfterGetRecord()
    begin
        // A missing parent is an integrity failure, never an empty receipt identity.
        if ReceiptHeader."No." <> Rec."Document No." then begin
            ReceiptHeader.SetLoadFields(SystemId);
            ReceiptHeader.Get(Rec."Document No.");
        end;
    end;
}
