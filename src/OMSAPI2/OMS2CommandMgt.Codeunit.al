codeunit 80240 "OMS2 Command Mgt"
{
    Permissions = tabledata "Purchase Header" = RIM,
                  tabledata "Purchase Line" = RIM,
                  tabledata "Purch. Rcpt. Header" = R;

    var
        NoLinesErr: Label 'Receipt command %1 has no quantities to receive.';
        OrderNotFoundErr: Label 'The selected purchase order no longer exists.';
        OrderReferenceMissingErr: Label 'Purchase order %1 has no OMS PO reference.';
        OrderNotReleasedErr: Label 'Purchase order %1 must be released before a receipt can be posted.';
        LineNotFoundErr: Label 'Item %1 is not an outstanding line on purchase order %2.';
        QuantityTooHighErr: Label 'Item %1 has only %2 outstanding on purchase order %3.';
        ReceiptNotFoundErr: Label 'Business Central posted the receipt for %1 but it could not be read back.';

    /**
     * Posts exactly what OMS recorded: the quantity on each command line becomes `Qty. to Receive`, every other
     * line is set to zero, and the receipt posts receive-only. A repeat of the same command returns the original
     * Business Central identities rather than posting twice.
     */
    procedure PostReceipt(var ReceiptCommand: Record "OMS2 Receipt Command")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReceiptCommandLine: Record "OMS2 Receipt Command Line";
        PurchPost: Codeunit "Purch.-Post";
        // The one object reused from the wider extension, authorized so receiving threshold breaches raise the
        // company's own error instead of a second rule invented here. Everything else is standard.
        ThresholdMgt: Codeunit "TBGC PO Rcvg Threshold Mgt";
    begin
        ReceiptCommand.LockTable();
        ReceiptCommand.Get(ReceiptCommand."OMS Receiving Ref. No.");
        if ReceiptCommand.Status = ReceiptCommand.Status::Posted then
            exit;

        ReceiptCommandLine.SetRange("OMS Receiving Ref. No.", ReceiptCommand."OMS Receiving Ref. No.");
        if ReceiptCommandLine.IsEmpty() then
            Error(NoLinesErr, ReceiptCommand."OMS Receiving Ref. No.");

        FindReleasedOrder(ReceiptCommand, PurchaseHeader);
        ApplyQuantities(ReceiptCommand, PurchaseHeader);

        PurchaseHeader.Validate("OMS Receiving Ref. No.", ReceiptCommand."OMS Receiving Ref. No.");
        PurchaseHeader.Validate("OMS Receiving Payload Hash", ReceiptCommand."OMS Receiving Payload Hash");
        if ReceiptCommand."Posting Date" <> 0D then
            PurchaseHeader.Validate("Posting Date", ReceiptCommand."Posting Date");
        PurchaseHeader.Receive := true;
        PurchaseHeader.Invoice := false;
        PurchaseHeader.Modify(true);

        ThresholdMgt.ValidatePurchaseOrderActualReceiptDates(PurchaseHeader);
        PurchPost.Run(PurchaseHeader);

        // A fully received order is deleted by posting, so the header is only cleaned up when it survives.
        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, ReceiptCommand."Purchase Order No.") then
            ThresholdMgt.ClearActualReceiptDatesAfterReceive(PurchaseHeader);

        PurchRcptHeader.SetCurrentKey("Order No.");
        PurchRcptHeader.SetRange("OMS Receiving Ref. No.", ReceiptCommand."OMS Receiving Ref. No.");
        if not PurchRcptHeader.FindLast() then
            Error(ReceiptNotFoundErr, ReceiptCommand."OMS Receiving Ref. No.");

        ReceiptCommand."Posted Receipt No." := PurchRcptHeader."No.";
        ReceiptCommand."Posted Receipt Id" := PurchRcptHeader.SystemId;
        ReceiptCommand."Posted At" := CurrentDateTime();
        ReceiptCommand.Status := ReceiptCommand.Status::Posted;
        ReceiptCommand."Error Message" := '';
        ReceiptCommand.Modify(true);
    end;

    local procedure FindReleasedOrder(var ReceiptCommand: Record "OMS2 Receipt Command"; var PurchaseHeader: Record "Purchase Header")
    begin
        if not PurchaseHeader.GetBySystemId(ReceiptCommand."Purchase Order Id") then
            Error(OrderNotFoundErr);
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Order);
        if PurchaseHeader."OMS PO Ref. No." = '' then
            Error(OrderReferenceMissingErr, PurchaseHeader."No.");
        if PurchaseHeader.Status <> PurchaseHeader.Status::Released then
            Error(OrderNotReleasedErr, PurchaseHeader."No.");

        ReceiptCommand."OMS PO Ref. No." := PurchaseHeader."OMS PO Ref. No.";
        ReceiptCommand."Purchase Order No." := PurchaseHeader."No.";
        ReceiptCommand.Modify(true);
    end;

    local procedure ApplyQuantities(ReceiptCommand: Record "OMS2 Receipt Command"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        ReceiptCommandLine: Record "OMS2 Receipt Command Line";
        ActualReceiptDate: Date;
    begin
        // The company requires an actual receipt date on every line being received, and this codeunit asks
        // TBGC PO Rcvg Threshold Mgt to enforce that before posting. The date is the day OMS recorded the
        // delivery on: its posting date. Without it every OMS receipt failed that rule before reaching BC.
        ActualReceiptDate := ReceiptCommand."Posting Date";
        if ActualReceiptDate = 0D then
            ActualReceiptDate := WorkDate();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                if PurchaseLine."Qty. to Receive" <> 0 then begin
                    PurchaseLine.Validate("Qty. to Receive", 0);
                    PurchaseLine.Modify(true);
                end;
            until PurchaseLine.Next() = 0;

        ReceiptCommandLine.SetRange("OMS Receiving Ref. No.", ReceiptCommand."OMS Receiving Ref. No.");
        if ReceiptCommandLine.FindSet() then
            repeat
                ReceiveOneLine(ReceiptCommandLine, PurchaseHeader, ActualReceiptDate);
            until ReceiptCommandLine.Next() = 0;
    end;

    local procedure ReceiveOneLine(ReceiptCommandLine: Record "OMS2 Receipt Command Line"; PurchaseHeader: Record "Purchase Header"; ActualReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ReceiptCommandLine."Item No.");
        if ReceiptCommandLine."Purchase Line No." <> 0 then
            PurchaseLine.SetRange("Line No.", ReceiptCommandLine."Purchase Line No.");
        PurchaseLine.SetFilter("Outstanding Quantity", '>%1', 0);
        if not PurchaseLine.FindFirst() then
            Error(LineNotFoundErr, ReceiptCommandLine."Item No.", PurchaseHeader."No.");

        if ReceiptCommandLine."Quantity to Receive" > PurchaseLine."Outstanding Quantity" then
            Error(QuantityTooHighErr, ReceiptCommandLine."Item No.",
                PurchaseLine."Outstanding Quantity", PurchaseHeader."No.");

        PurchaseLine.Validate("Qty. to Receive", ReceiptCommandLine."Quantity to Receive");
        PurchaseLine.Validate("TBGC Actual Receipt Date", ActualReceiptDate);
        PurchaseLine.Modify(true);
    end;
}
