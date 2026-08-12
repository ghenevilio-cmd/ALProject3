tableextension 80293 "TBGC PO Rcvg Threshold Setup" extends "Purchases & Payables Setup"
{
    fields
    {
        field(80297; "TBGC PO Rcvg Threshold %"; Decimal)
        {
            Caption = 'PO Receiving Threshold %';
            DataClassification = CustomerContent;
            MinValue = 0;
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
            ObsoleteState = Pending;
            ObsoleteReason = 'The receiving threshold is now configured per Item Family.';
            ObsoleteTag = '1.0.1.25';
        }

        field(80298; "TBGC Retroactive Rcvg Window"; Integer)
        {
            Caption = 'Retroactive Receiving Window';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
    }
}

pageextension 80293 "TBGC PO Rcvg Threshold Setup" extends "Purchases & Payables Setup"
{
    layout
    {
        addlast(General)
        {
            field("TBGC Retroactive Rcvg Window"; Rec."TBGC Retroactive Rcvg Window")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies how many days back from the work date users can enter as the actual receipt date.';
            }
        }
    }
}

pageextension 80286 "TBGC PO Rcvg Threshold Line" extends "Purchase Order Subform"
{
    layout
    {
        modify(Type)
        {
            Editable = not MarketListReceivingMode;
        }
        modify("No.")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("Item Reference No.")
        {
            Editable = not MarketListReceivingMode;
        }
        modify(Description)
        {
            Editable = not MarketListReceivingMode;
        }
        modify("Description 2")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("Location Code")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("Bin Code")
        {
            Editable = not MarketListReceivingMode;
        }
        modify(Quantity)
        {
            Editable = not MarketListReceivingMode;
        }
        modify("Unit of Measure Code")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("Direct Unit Cost")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("Line Discount %")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("Line Amount")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("Qty. to Invoice")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("Qty. to Receive")
        {
            Editable = MarketListLineEditable;
        }
        addafter("Qty. to Receive")
        {
            field("TBGC Actual Receipt Date"; Rec."TBGC Actual Receipt Date")
            {
                ApplicationArea = All;
                Editable = MarketListLineEditable;
                ToolTip = 'Specifies the actual receipt date for the quantity being received.';
            }
        }
        modify("VAT Bus. Posting Group")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("VAT Prod. Posting Group")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("WHT Product Posting Group PHL")
        {
            Editable = not MarketListReceivingMode;
        }
        modify("WHT Business Posting Group PHL")
        {
            Editable = not MarketListReceivingMode;
        }
        addafter(Quantity)
        {
            field("TBGC Original Ordered Qty"; Rec."TBGC Original Ordered Qty")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the original ordered quantity before standard over-receipt handling increased the line quantity.';
            }
        }
    }

    actions
    {
        modify(SelectMultiItems)
        {
            Visible = not MarketListReceivingMode;
        }
        modify("&Line")
        {
            Visible = not MarketListReceivingMode;
        }
        modify("F&unctions")
        {
            Visible = not MarketListReceivingMode;
        }
        modify("O&rder")
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Errors)
        {
            Visible = not MarketListReceivingMode;
        }
        modify("Page")
        {
            Visible = not MarketListReceivingMode;
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateMarketListReceivingMode();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        UpdateMarketListReceivingMode();
        if MarketListReceivingMode then
            Error(MarketListLineInsertErr);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        UpdateMarketListReceivingMode();
        if MarketListReceivingMode then
            Error(MarketListLineDeleteErr);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateMarketListReceivingMode();
    end;

    local procedure UpdateMarketListReceivingMode()
    var
        MarketListReceivingContext: Codeunit "TBGC ML Receiving Context";
    begin
        MarketListReceivingMode := MarketListReceivingContext.IsMarketListReceivingPurchaseOrder(Rec."Document No.");
        MarketListLineEditable := not MarketListReceivingContext.IsMarketListReceivingReadOnly(Rec."Document No.");
    end;

    var
        MarketListLineDeleteErr: Label 'Deleting purchase order lines is not allowed when opened from Market List Receiving. You can only update Qty. to Receive.';
        MarketListLineInsertErr: Label 'Creating purchase order lines is not allowed when opened from Market List Receiving. You can only update Qty. to Receive.';
        MarketListReceivingMode: Boolean;
        MarketListLineEditable: Boolean;
}

codeunit 80293 "TBGC PO Rcvg Threshold Mgt"
{
    Permissions = tabledata "Over-Receipt Code" = RIM;
    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeValidateEvent', 'Qty. to Receive', false, false)]
    local procedure PurchaseLineOnBeforeValidateQtyToReceive(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        // CurrFieldNo = 0 means a programmatic validate (e.g. from Purch.-Post), not a user edit.
        // Never prompt there: the dialog would hold the Item Ledger Entry lock at human speed.
        if CurrFieldNo = 0 then
            exit;

        if IsQuantityUpdate(Rec, xRec) then
            exit;

        ApplyStandardOverReceiptTolerance(Rec);
        ConfirmThresholdReceipt(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'Qty. to Receive', false, false)]
    local procedure PurchaseLineOnAfterValidateQtyToReceive(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    var
        MarketListReceivingContext: Codeunit "TBGC ML Receiving Context";
    begin
        // See PurchaseLineOnBeforeValidateQtyToReceive: skip programmatic validates so posting
        // is never interrupted by this extension's confirmations or errors.
        if CurrFieldNo = 0 then
            exit;

        if IsQuantityUpdate(Rec, xRec) then
            exit;

        CaptureOriginalOrderedQty(Rec, xRec);
        ValidateQtyToReceiveThreshold(Rec);
        if MarketListReceivingContext.IsMarketListReceivingPurchaseOrder(Rec."Document No.") then
            ValidateActualReceiptDate(Rec);
    end;

    procedure ValidatePurchaseOrderActualReceiptDates(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("Qty. to Receive", '>%1', 0);
        if PurchaseLine.FindSet() then
            repeat
                ValidateActualReceiptDate(PurchaseLine);
            until PurchaseLine.Next() = 0;
    end;

    procedure ClearActualReceiptDatesAfterReceive(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("TBGC Actual Receipt Date", '<>%1', 0D);
        if PurchaseLine.FindSet(true) then
            repeat
                PurchaseLine."TBGC Actual Receipt Date" := 0D;
                PurchaseLine.Modify(false);
            until PurchaseLine.Next() = 0;
    end;

    procedure ValidateActualReceiptDate(PurchaseLine: Record "Purchase Line")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        EarliestAllowedDate: Date;
        WorkDateValue: Date;
    begin
        if not IsReceivablePurchaseOrderItemLine(PurchaseLine) then
            exit;

        if PurchaseLine."TBGC Actual Receipt Date" = 0D then
            Error(
              'Actual Receipt Date is required for item %1 when Qty. to Receive is greater than zero.',
              PurchaseLine."No.");

        WorkDateValue := WorkDate();
        if PurchaseLine."TBGC Actual Receipt Date" > WorkDateValue then
            Error(
              'Actual Receipt Date %1 cannot be later than the work date %2.',
              PurchaseLine."TBGC Actual Receipt Date",
              WorkDateValue);

        if not PurchasesPayablesSetup.Get() then
            exit;

        EarliestAllowedDate := CalcDate(StrSubstNo('<-%1D>', PurchasesPayablesSetup."TBGC Retroactive Rcvg Window"), WorkDateValue);
        if PurchaseLine."TBGC Actual Receipt Date" < EarliestAllowedDate then
            Error(
              'Actual Receipt Date %1 is outside the allowed retroactive receiving window. The earliest allowed date is %2.',
              PurchaseLine."TBGC Actual Receipt Date",
              EarliestAllowedDate);
    end;

    local procedure ApplyStandardOverReceiptTolerance(var PurchaseLine: Record "Purchase Line")
    var
        BaselineQty: Decimal;
        MaxAllowedQty: Decimal;
        TotalReceivedAfterReceive: Decimal;
        ThresholdPct: Decimal;
        OverReceiptCode: Code[20];
    begin
        if not IsReceivablePurchaseOrderItemLine(PurchaseLine) then
            exit;

        ThresholdPct := GetThresholdPct(PurchaseLine);
        if ThresholdPct <= 0 then
            exit;

        BaselineQty := GetOriginalOrderedQty(PurchaseLine);
        MaxAllowedQty := BaselineQty * (1 + (ThresholdPct / 100));
        TotalReceivedAfterReceive := PurchaseLine."Quantity Received" + PurchaseLine."Qty. to Receive";

        if TotalReceivedAfterReceive <= BaselineQty then
            exit;

        if TotalReceivedAfterReceive > MaxAllowedQty then
            exit;

        OverReceiptCode := EnsureThresholdOverReceiptCode(ThresholdPct);
        if (OverReceiptCode <> '') and (PurchaseLine."Over-Receipt Code" <> OverReceiptCode) then
            PurchaseLine."Over-Receipt Code" := OverReceiptCode;
    end;

    local procedure EnsureThresholdOverReceiptCode(ThresholdPct: Decimal): Code[20]
    var
        OverReceiptCode: Record "Over-Receipt Code";
        CodeValue: Code[20];
    begin
        CodeValue := CopyStr(
            StrSubstNo('TBGC%1', Format(Round(ThresholdPct * 100000, 1, '='), 0, 9)),
            1,
            MaxStrLen(CodeValue));

        if OverReceiptCode.Get(CodeValue) then begin
            if OverReceiptCode."Over-Receipt Tolerance %" <> ThresholdPct then
                Error(OverReceiptCodeMismatchErr, OverReceiptCode.Code, OverReceiptCode."Over-Receipt Tolerance %", ThresholdPct);
            exit(OverReceiptCode.Code);
        end;

        OverReceiptCode.Init();
        OverReceiptCode.Code := CodeValue;
        OverReceiptCode.Description := CopyStr(StrSubstNo('TBGC PO Receiving Threshold %1%', ThresholdPct), 1, MaxStrLen(OverReceiptCode.Description));
        OverReceiptCode."Over-Receipt Tolerance %" := ThresholdPct;
        OverReceiptCode.Insert(false);
        exit(OverReceiptCode.Code);
    end;

    local procedure ConfirmThresholdReceipt(PurchaseLine: Record "Purchase Line")
    var
        BaselineQty: Decimal;
        MaxAllowedQty: Decimal;
        TotalReceivedAfterReceive: Decimal;
        ThresholdPct: Decimal;
        ThresholdReceiptQst: Label 'The Qty. to Receive exceeds the ordered quantity but is within the allowed receiving threshold. Do you want to continue?';
    begin
        if not IsReceivablePurchaseOrderItemLine(PurchaseLine) then
            exit;

        ThresholdPct := GetThresholdPct(PurchaseLine);
        BaselineQty := GetOriginalOrderedQty(PurchaseLine);
        MaxAllowedQty := BaselineQty * (1 + (ThresholdPct / 100));
        TotalReceivedAfterReceive := PurchaseLine."Quantity Received" + PurchaseLine."Qty. to Receive";

        if TotalReceivedAfterReceive <= BaselineQty then
            exit;

        if TotalReceivedAfterReceive > MaxAllowedQty then
            Error(
              'Qty. to Receive for item %1 cannot make the total received quantity exceed %2. The original ordered quantity is %3 and the PO Receiving Threshold is %4%.',
              PurchaseLine."No.",
              MaxAllowedQty,
              BaselineQty,
              ThresholdPct);

        if GuiAllowed() then
            if not Confirm(ThresholdReceiptQst, false) then
                Error('');
    end;

    local procedure CaptureOriginalOrderedQty(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
        if not IsPurchaseOrderItemLine(PurchaseLine) then
            exit;

        if PurchaseLine."TBGC Original Ordered Qty" <> 0 then
            exit;

        if xPurchaseLine.Quantity <= 0 then
            exit;

        if PurchaseLine.Quantity <= xPurchaseLine.Quantity then
            exit;

        PurchaseLine."TBGC Original Ordered Qty" := xPurchaseLine.Quantity;
    end;

    local procedure ValidateQtyToReceiveThreshold(PurchaseLine: Record "Purchase Line")
    var
        BaselineQty: Decimal;
        MaxAllowedQty: Decimal;
        TotalReceivedAfterReceive: Decimal;
        ThresholdPct: Decimal;
    begin
        if not IsReceivablePurchaseOrderItemLine(PurchaseLine) then
            exit;

        ThresholdPct := GetThresholdPct(PurchaseLine);

        BaselineQty := GetOriginalOrderedQty(PurchaseLine);
        MaxAllowedQty := BaselineQty * (1 + (ThresholdPct / 100));
        TotalReceivedAfterReceive := PurchaseLine."Quantity Received" + PurchaseLine."Qty. to Receive";

        if TotalReceivedAfterReceive > MaxAllowedQty then
            Error(
              'Qty. to Receive for item %1 cannot make the total received quantity exceed %2. The original ordered quantity is %3 and the PO Receiving Threshold is %4%.',
              PurchaseLine."No.",
              MaxAllowedQty,
              BaselineQty,
              ThresholdPct);
    end;

    local procedure IsReceivablePurchaseOrderItemLine(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if not IsPurchaseOrderItemLine(PurchaseLine) then
            exit(false);

        if PurchaseLine.Quantity <= 0 then
            exit(false);

        if PurchaseLine."Qty. to Receive" <= 0 then
            exit(false);

        exit(true);
    end;

    local procedure IsQuantityUpdate(PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit(PurchaseLine.Quantity <> xPurchaseLine.Quantity);
    end;

    local procedure IsPurchaseOrderItemLine(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Order then
            exit(false);

        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit(false);

        exit(true);
    end;

    local procedure GetOriginalOrderedQty(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        if PurchaseLine."TBGC Original Ordered Qty" <> 0 then
            exit(PurchaseLine."TBGC Original Ordered Qty");

        exit(PurchaseLine.Quantity);
    end;

    local procedure GetThresholdPct(PurchaseLine: Record "Purchase Line"): Decimal
    var
        Item: Record Item;
        ItemFamily: Record "LSC Item Family";
    begin
        if PurchaseLine."No." = '' then
            exit(0);

        Item.SetLoadFields("LSC Item Family Code");
        if not Item.Get(PurchaseLine."No.") then
            exit(0);

        if Item."LSC Item Family Code" = '' then
            exit(0);

        ItemFamily.SetLoadFields("TBGC PO Rcvg Threshold %");
        if not ItemFamily.Get(Item."LSC Item Family Code") then
            exit(0);

        exit(ItemFamily."TBGC PO Rcvg Threshold %");
    end;

    var
        OverReceiptCodeMismatchErr: Label 'Over-Receipt Code %1 has tolerance %2%%, but the item family requires %3%%. Correct the Over-Receipt Code before receiving.';
}