codeunit 80240 "OMS2 Command Mgt"
{
    Permissions = tabledata "Purchase Header" = RIM,
                  tabledata "Purchase Line" = RIM,
                  tabledata "Purch. Rcpt. Header" = R;

    var
        CommandPostedErr: Label 'Receipt command %1 already posted receipt %2.';
        ChangedReplayErr: Label 'Receipt command %1 was already used with a different payload.';
        NoLinesErr: Label 'Receipt command %1 has no quantities to receive.';
        OrderNotFoundErr: Label 'No open purchase order carries OMS PO reference %1.';
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

    /** A replay carrying a different body must fail rather than post a second receipt. */
    procedure AssertReplayMatches(ReceiptCommand: Record "OMS2 Receipt Command"; PayloadHash: Code[64])
    begin
        if ReceiptCommand."OMS Receiving Payload Hash" <> PayloadHash then
            Error(ChangedReplayErr, ReceiptCommand."OMS Receiving Ref. No.");
        if ReceiptCommand.Status = ReceiptCommand.Status::Posted then
            Error(CommandPostedErr, ReceiptCommand."OMS Receiving Ref. No.", ReceiptCommand."Posted Receipt No.");
    end;

    local procedure FindReleasedOrder(var ReceiptCommand: Record "OMS2 Receipt Command"; var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("OMS PO Ref. No.", ReceiptCommand."OMS PO Ref. No.");
        if not PurchaseHeader.FindFirst() then
            Error(OrderNotFoundErr, ReceiptCommand."OMS PO Ref. No.");
        if PurchaseHeader.Status <> PurchaseHeader.Status::Released then
            Error(OrderNotReleasedErr, PurchaseHeader."No.");

        ReceiptCommand."Purchase Order No." := PurchaseHeader."No.";
        ReceiptCommand.Modify(true);
    end;

    local procedure ApplyQuantities(ReceiptCommand: Record "OMS2 Receipt Command"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        ReceiptCommandLine: Record "OMS2 Receipt Command Line";
    begin
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
                ReceiveOneLine(ReceiptCommandLine, PurchaseHeader);
            until ReceiptCommandLine.Next() = 0;
    end;

    local procedure ReceiveOneLine(ReceiptCommandLine: Record "OMS2 Receipt Command Line"; PurchaseHeader: Record "Purchase Header")
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
        PurchaseLine.Modify(true);
    end;
}
