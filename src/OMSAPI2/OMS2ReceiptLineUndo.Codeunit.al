codeunit 80262 "OMS2 Receipt Line Undo"
{
    EventSubscriberInstance = Manual;

    [CommitBehavior(CommitBehavior::Error)]
    procedure Execute(SelectedLineId: Guid; RequestId: Guid; ExpectedCompanyId: Guid; ExpectedReceiptId: Guid; ExpectedReceiptLineNumber: Integer;
        ExpectedOrderNumber: Code[20]; ExpectedOrderLineNumber: Integer; ExpectedVendorNumber: Code[20];
        ExpectedItemNumber: Code[20]; ExpectedLocationCode: Code[10]; ExpectedConceptCode: Code[20];
        ExpectedUnitOfMeasureCode: Code[10]; ExpectedQuantity: Decimal; ExpectedQuantityBase: Decimal;
        ExpectedModifiedAt: DateTime): Guid
    var
        ReceiptLine: Record "Purch. Rcpt. Line";
        ReceiptHeader: Record "Purch. Rcpt. Header";
        CompanyRecord: Record Company;
        Item: Record Item;
        Location: Record Location;
        WarehouseReceiptLine: Record "Posted Whse. Receipt Line";
        StandardUndo: Codeunit "Undo Purchase Receipt Line";
    begin
        if IsNullGuid(RequestId) or IsNullGuid(SelectedLineId) or IsNullGuid(ExpectedReceiptId) then
            Error(ChangedErr);
        CompanyRecord.Get(CompanyName());
        if CompanyRecord.Id <> ExpectedCompanyId then
            Error(ChangedErr);

        // Lock before re-reading; an earlier HTTP invoice check cannot protect this financial action.
        ReceiptLine.LockTable();
        if not ReceiptLine.GetBySystemId(SelectedLineId) then
            Error(ChangedErr);
        ReceiptHeader.Get(ReceiptLine."Document No.");
        if (ReceiptHeader.SystemId <> ExpectedReceiptId) or (ReceiptLine."Line No." <> ExpectedReceiptLineNumber) or
           (ReceiptLine."Order No." <> ExpectedOrderNumber) or (ReceiptLine."Order Line No." <> ExpectedOrderLineNumber) or
           (ReceiptLine."Buy-from Vendor No." <> ExpectedVendorNumber) or (ReceiptLine."No." <> ExpectedItemNumber) or
           (ReceiptLine."Location Code" <> ExpectedLocationCode) or (ReceiptLine."Shortcut Dimension 1 Code" <> ExpectedConceptCode) or
           (ReceiptLine."Unit of Measure Code" <> ExpectedUnitOfMeasureCode) or (ReceiptLine.SystemModifiedAt <> ExpectedModifiedAt) then
            Error(ChangedErr);
        ReceiptLine.TestField(Type, ReceiptLine.Type::Item);
        ReceiptLine.TestField(Correction, false);
        ReceiptLine.TestField("Quantity Invoiced", 0);
        ReceiptLine.TestField("Qty. Invoiced (Base)", 0);
        if (ExpectedQuantity <= 0) or (ExpectedQuantityBase <= 0) or
           (ReceiptLine.Quantity <> ExpectedQuantity) or (ReceiptLine."Quantity (Base)" <> ExpectedQuantityBase) or
           (ReceiptLine."Qty. Rcd. Not Invoiced" <> ExpectedQuantity) or
           (ReceiptLine.Quantity * ReceiptLine."Qty. per Unit of Measure" <> ReceiptLine."Quantity (Base)") then
            Error(QuantityErr);
        if (ReceiptLine."Sales Order No." <> '') or (ReceiptLine."Special Order Sales No." <> '') or
           (ReceiptLine."Job No." <> '') or ReceiptLine.IsProdOrder() then
            Error(UnsupportedErr);
        Item.Get(ReceiptLine."No.");
        if Item."Item Tracking Code" <> '' then
            Error(UnsupportedErr);
        if ReceiptLine."Location Code" <> '' then begin
            Location.Get(ReceiptLine."Location Code");
            if Location."Require Receive" or Location."Require Put-away" then
                Error(UnsupportedErr);
        end;
        WarehouseReceiptLine.SetRange("Source Type", Database::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source No.", ReceiptLine."Order No.");
        WarehouseReceiptLine.SetRange("Source Line No.", ReceiptLine."Order Line No.");
        WarehouseReceiptLine.SetRange("Posted Source No.", ReceiptLine."Document No.");
        if not WarehouseReceiptLine.IsEmpty() then
            Error(UnsupportedErr);

        OriginalId := ReceiptLine.SystemId;
        OriginalQuantity := ReceiptLine.Quantity;
        OriginalQuantityBase := ReceiptLine."Quantity (Base)";
        Clear(CorrectionId);
        ReceiptLine.SetRange("Document No.", ReceiptLine."Document No.");
        ReceiptLine.SetRange("Line No.", ReceiptLine."Line No.");
        ReceiptLine.SetRange(SystemId, OriginalId);
        if ReceiptLine.Count() <> 1 then
            Error(ChangedErr);
        if not BindSubscription(this) then
            Error(ChangedErr);
        StandardUndo.SetHideDialog(true);
        StandardUndo.Run(ReceiptLine);
        UnbindSubscription(this);
        if IsNullGuid(CorrectionId) then
            Error(ChangedErr);
        ReceiptLine.Reset();
        ReceiptLine.GetBySystemId(OriginalId);
        ReceiptLine.TestField(Correction, true);
        exit(CorrectionId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnAfterNewPurchRcptLineInsert', '', false, false)]
    local procedure CaptureCorrection(var NewPurchRcptLine: Record "Purch. Rcpt. Line"; OldPurchRcptLine: Record "Purch. Rcpt. Line";
        var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var SkipInsertItemEntryRelation: Boolean)
    begin
        // Observe the standard result; never replace posting logic or set IsHandled/Skip flags.
        if (OldPurchRcptLine.SystemId <> OriginalId) or not IsNullGuid(CorrectionId) or
           not NewPurchRcptLine.Correction or (NewPurchRcptLine.Quantity <> -OriginalQuantity) or
           (NewPurchRcptLine."Quantity (Base)" <> -OriginalQuantityBase) then
            Error(ChangedErr);
        CorrectionId := NewPurchRcptLine.SystemId;
    end;

    var
        OriginalId: Guid;
        CorrectionId: Guid;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        ChangedErr: Label 'OMS Undo receipt identity or result changed. No automatic retry is permitted.';
        QuantityErr: Label 'OMS Undo must match the entire disputed receipt-line quantity and base quantity.';
        UnsupportedErr: Label 'OMS Undo for this linked, tracked or warehouse receipt requires separate runtime verification. Use the existing Business Central process.';
}
