codeunit 80208 "TBGC Draft Order Mgt"
{
    [EventSubscriber(ObjectType::Table, Database::"TBGC Draft Order Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DraftOrderLineOnAfterDelete(var Rec: Record "TBGC Draft Order Line"; RunTrigger: Boolean)
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
        RemainingDraftLines: Record "TBGC Draft Order Line";
    begin
        if not RunTrigger then
            exit;

        if Rec."Document No." = '' then
            exit;

        RemainingDraftLines.SetRange("Document No.", Rec."Document No.");
        if not RemainingDraftLines.IsEmpty() then
            exit;

        if DraftOrderHeader.Get(Rec."Document No.") then
            DraftOrderHeader.Delete(true);
    end;

    procedure SaveDraftOrder(CartJson: Text; IsCheckoutDraft: Boolean): Text
    var
        MarketListAccessMgt: Codeunit "TBGC Market List Access Mgt";
        CheckoutState: Codeunit "TBGC POS Checkout State";
        OrderHistoryMgt: Codeunit "TBGC APL Order History Mgt";
        ReleasedDateMgt: Codeunit "TBGC Released Date Mgt";
        JRoot: JsonObject;
        JLines: JsonArray;
        JToken: JsonToken;
        LineToken: JsonToken;
        LineObj: JsonObject;
        DraftOrderHeader: Record "TBGC Draft Order Header";
        DraftOrderLine: Record "TBGC Draft Order Line";
        ResultObj: JsonObject;
        ResultArr: JsonArray;
        ResultJson: Text;
        ResultStatus: Text;
        LocationCode: Code[20];
        ExpectedDeliveryDateText: Text;
        ExpectedReceiptDate: Date;
        ReleasedDateText: Text;
        ReleasedDate: Date;
        VendorNo: Code[20];
        ItemNo: Code[20];
        Description: Text[100];
        BrandCode: Code[20];
        BrandDescription: Text[100];
        UOMCode: Code[20];
        Qty: Decimal;
        DirectUnitCost: Decimal;
        LineNo: Integer;
        i: Integer;
        HistoryLinesJson: Text;
        DraftOrderNosByVendor: Dictionary of [Code[20], Code[20]];
        DraftOrderLineNosByVendor: Dictionary of [Code[20], Integer];
        DraftOrderNo: Code[20];
    begin
        if not MarketListAccessMgt.CanCurrentUserOrder() then
            Error('You are not allowed to order.');

        if not JRoot.ReadFrom(CartJson) then
            Error('Invalid cart JSON.');

        if not JRoot.Get('lines', JToken) then
            Error('Cart lines not found.');

        JLines := JToken.AsArray();
        if JLines.Count() = 0 then
            Error('Cart lines not found.');

        if JRoot.Get('locationCode', JToken) then
            LocationCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(LocationCode));

        if LocationCode = '' then
            Error('No location assigned. You cannot save a draft without a location.');

        ValidateLocationCode(LocationCode);

        if JRoot.Get('expectedDeliveryDate', JToken) then begin
            ExpectedDeliveryDateText := JToken.AsValue().AsText();
            Evaluate(ExpectedReceiptDate, ExpectedDeliveryDateText);
        end;

        if ExpectedReceiptDate = 0D then
            Error('Please select an Expected Delivery Date.');

        if ExpectedReceiptDate < Today then
            Error('Expected Delivery Date cannot be earlier than today.');

        ValidateDraftLines(JLines);
        ValidateMinimumOrderAmount(JLines);

        if IsCheckoutDraft then
            ReleasedDate := Today
        else
            if JRoot.Get('releasedDate', JToken) then begin
                ReleasedDateText := JToken.AsValue().AsText();
                Evaluate(ReleasedDate, ReleasedDateText);
            end;

        if ReleasedDate = 0D then
            Error('Released Date is required.');

        if ReleasedDate > ExpectedReceiptDate then
            Error('Need by Date cannot be earlier than Released Date. Need by Date is %1.', ExpectedReceiptDate);

        ReleasedDateMgt.ValidateReleasedDate(ReleasedDate);

        for i := 0 to JLines.Count() - 1 do begin
            JLines.Get(i, LineToken);
            LineObj := LineToken.AsObject();

            Clear(VendorNo);
            Clear(ItemNo);
            Clear(Description);
            Clear(BrandCode);
            Clear(BrandDescription);
            Clear(UOMCode);
            Clear(Qty);
            Clear(DirectUnitCost);

            if LineObj.Get('vendorNo', JToken) then
                VendorNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(VendorNo))
            else
                Error('Vendor No. missing on one cart line.');

            if LineObj.Get('itemId', JToken) then
                ItemNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(ItemNo))
            else
                Error('Item No. missing on one cart line.');

            if LineObj.Get('name', JToken) then
                Description := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Description));

            if LineObj.Get('brandCode', JToken) then
                BrandCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(BrandCode));

            if LineObj.Get('brandDescription', JToken) then
                BrandDescription := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(BrandDescription));

            if LineObj.Get('uom', JToken) then
                UOMCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(UOMCode));

            if LineObj.Get('quantity', JToken) then
                Qty := JToken.AsValue().AsDecimal()
            else
                Qty := 1;

            if Qty <= 0 then
                Error('Quantity must be greater than 0 on item %1.', ItemNo);

            if LineObj.Get('price', JToken) then
                DirectUnitCost := JToken.AsValue().AsDecimal();

            if not DraftOrderNosByVendor.ContainsKey(VendorNo) then begin
                Clear(DraftOrderHeader);
                DraftOrderHeader.Init();
                DraftOrderHeader."Location Code" := LocationCode;
                DraftOrderHeader."Vendor No." := VendorNo;
                DraftOrderHeader.Status := DraftOrderHeader.Status::Open;
                DraftOrderHeader."Expected Receipt Date" := ExpectedReceiptDate;
                DraftOrderHeader."Released Date" := ReleasedDate;
                if IsCheckoutDraft then
                    DraftOrderHeader.Type := DraftOrderHeader.Type::Checkout
                else
                    DraftOrderHeader.Type := DraftOrderHeader.Type::Draft;
                DraftOrderHeader.Insert(true);

                DraftOrderNo := DraftOrderHeader."No.";
                DraftOrderNosByVendor.Add(VendorNo, DraftOrderNo);
                DraftOrderLineNosByVendor.Add(VendorNo, 0);
                CheckoutState.AddCreatedDraftNo(DraftOrderNo);
                ResultArr.Add(DraftOrderNo);
            end else
                DraftOrderNosByVendor.Get(VendorNo, DraftOrderNo);

            DraftOrderLineNosByVendor.Get(VendorNo, LineNo);
            LineNo += 10000;
            DraftOrderLineNosByVendor.Set(VendorNo, LineNo);

            DraftOrderLine.Init();
            DraftOrderLine."Document No." := DraftOrderNo;
            DraftOrderLine."Line No." := LineNo;
            DraftOrderLine."Vendor No." := VendorNo;
            DraftOrderLine."Item No." := ItemNo;
            DraftOrderLine.Description := Description;
            DraftOrderLine."TBGC Brand Code" := BrandCode;
            DraftOrderLine."TBGC Brand Description" := BrandDescription;
            DraftOrderLine."Unit of Measure Code" := UOMCode;
            DraftOrderLine.Quantity := Qty;
            DraftOrderLine."Direct Unit Cost" := DirectUnitCost;
            DraftOrderLine.Insert();
        end;

        JLines.WriteTo(HistoryLinesJson);
        OrderHistoryMgt.SaveOrderHistory(LocationCode, ExpectedReceiptDate, HistoryLinesJson);

        ResultObj.Add('documentNumbers', ResultArr);
        if IsCheckoutDraft then
            ResultStatus := 'checkout'
        else
            ResultStatus := 'draft';

        ResultObj.Add('status', ResultStatus);
        ResultObj.WriteTo(ResultJson);
        exit(ResultJson);
    end;

    procedure OpenDraftOrdersForLocation(LocationCode: Code[20])
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
        DraftOrders: Page "TBGC Draft Orders";
    begin
        if LocationCode <> '' then
            DraftOrderHeader.SetRange("Location Code", LocationCode);

        DraftOrders.SetTableView(DraftOrderHeader);
        DraftOrders.RunModal();
    end;

    procedure CanEditDraftOrder(DocumentNo: Code[20]): Boolean
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
        MarketListAccessMgt: Codeunit "TBGC Market List Access Mgt";
    begin
        if not DraftOrderHeader.Get(DocumentNo) then
            exit(false);

        if DraftOrderHeader.Status <> DraftOrderHeader.Status::Open then
            exit(false);

        case DraftOrderHeader.Type of
            DraftOrderHeader.Type::Draft:
                ;
            DraftOrderHeader.Type::Checkout:
                begin
                    if not MarketListAccessMgt.IsCurrentUserDeleteEditAllowed() then
                        exit(false);

                    exit(true);
                end;
            else
                exit(false);
        end;

        if DraftOrderHeader."Released Date" = 0D then
            exit(false);

        if Today < DraftOrderHeader."Released Date" then
            exit(true);

        if Today > DraftOrderHeader."Released Date" then
            exit(false);

        exit(Time <= 120000T);
    end;

    procedure GetDraftSummaryJson(LocationCode: Code[20]): Text
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
        SummaryObj: JsonObject;
        SummaryJson: Text;
    begin
        SummaryObj.Add('locationCode', LocationCode);
        SummaryObj.Add('draftOrderCount', 0);

        if LocationCode <> '' then
            DraftOrderHeader.SetRange("Location Code", LocationCode);

        DraftOrderHeader.SetRange(Status, DraftOrderHeader.Status::Open);
        SummaryObj.Replace('draftOrderCount', DraftOrderHeader.Count());
        SummaryObj.WriteTo(SummaryJson);

        exit(SummaryJson);
    end;

    local procedure ValidateLocationCode(LocationCode: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Global Dimension 1 Code" = '' then
            exit;

        DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionValue.SetRange(Code, LocationCode);
        if DimensionValue.IsEmpty() then
            Error(
              'Draft save stopped. Location/BU Code %1 is not set up as a valid dimension value for %2.',
              LocationCode,
              GeneralLedgerSetup."Global Dimension 1 Code");
    end;

    local procedure ValidateDraftLines(JLines: JsonArray)
    var
        JToken: JsonToken;
        LineToken: JsonToken;
        LineObj: JsonObject;
        VendorNo: Code[20];
        ItemNo: Code[20];
        i: Integer;
    begin
        for i := 0 to JLines.Count() - 1 do begin
            JLines.Get(i, LineToken);
            LineObj := LineToken.AsObject();

            Clear(VendorNo);
            Clear(ItemNo);

            if LineObj.Get('vendorNo', JToken) then
                VendorNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(VendorNo));

            if VendorNo = '' then
                Error('Vendor No. missing on one cart line.');

            if LineObj.Get('itemId', JToken) then
                ItemNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(ItemNo));

            if ItemNo = '' then
                Error('Item No. missing on one cart line.');
        end;
    end;

    local procedure ValidateMinimumOrderAmount(JLines: JsonArray)
    var
        Vendor: Record Vendor;
        JToken: JsonToken;
        LineToken: JsonToken;
        LineObj: JsonObject;
        LineVendorNo: Code[20];
        Qty: Decimal;
        DirectUnitCost: Decimal;
        OrderTotalAmount: Decimal;
        i: Integer;
        VendorTotals: Dictionary of [Code[20], Decimal];
        CurrentVendorNo: Code[20];
    begin
        for i := 0 to JLines.Count() - 1 do begin
            JLines.Get(i, LineToken);
            LineObj := LineToken.AsObject();

            Clear(LineVendorNo);
            Clear(Qty);
            Clear(DirectUnitCost);

            if LineObj.Get('vendorNo', JToken) then
                LineVendorNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(LineVendorNo));

            if LineObj.Get('quantity', JToken) then
                Qty := JToken.AsValue().AsDecimal()
            else
                Qty := 0;

            if LineObj.Get('price', JToken) then
                DirectUnitCost := JToken.AsValue().AsDecimal();

            if LineVendorNo = '' then
                continue;

            OrderTotalAmount := Qty * DirectUnitCost;
            if VendorTotals.ContainsKey(LineVendorNo) then begin
                VendorTotals.Get(LineVendorNo, Qty);
                VendorTotals.Set(LineVendorNo, Qty + OrderTotalAmount);
            end else
                VendorTotals.Add(LineVendorNo, OrderTotalAmount);
        end;

        foreach CurrentVendorNo in VendorTotals.Keys() do begin
            if (CurrentVendorNo = '') or (not Vendor.Get(CurrentVendorNo)) then
                continue;

            VendorTotals.Get(CurrentVendorNo, OrderTotalAmount);
            if (Vendor."TBGC Minimum Order Amount" > 0) and (OrderTotalAmount < Vendor."TBGC Minimum Order Amount") then
                Error(
                  'Minimum order not reached for vendor %1. Required minimum amount is %2, but current order total is %3.',
                  CurrentVendorNo,
                  Vendor."TBGC Minimum Order Amount",
                  Round(OrderTotalAmount, 0.01));
        end;
    end;
}
