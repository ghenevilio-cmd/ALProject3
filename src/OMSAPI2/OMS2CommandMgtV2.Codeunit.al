codeunit 80249 "OMS2 Command Mgt V2"
{
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Purchase Header" = RIM,
                  tabledata "Purchase Line" = RIM,
                  tabledata "Purch. Rcpt. Header" = R,
                  tabledata "TBGC Draft Order Header" = RIM,
                  tabledata "TBGC Draft Order Line" = RIM,
                  tabledata "TBGC Brand List" = R;

    procedure CreateDraft(var Command: Record "OMS2 Draft Command")
    var
        CommandLine: Record "OMS2 Draft Command Line";
        DraftHeader: Record "TBGC Draft Order Header";
        DraftLine: Record "TBGC Draft Order Line";
        Item: Record Item;
        ValidationMgt: Codeunit "TBGC PO Validation Mgt";
    begin
        Command.LockTable();
        Command.Get(Command."Command Id");
        if Command.Status = Command.Status::Created then
            exit;

        CommandLine.SetRange("Command Id", Command."Command Id");
        if CommandLine.IsEmpty() then
            Error('Draft command %1 has no lines.', Command."Command Id");

        ValidationMgt.ValidateHeaderBeforeInsert(Command."Vendor No.", Command."Location Code", Command."Expected Receipt Date");
        DraftHeader.Init();
        DraftHeader.Validate("Vendor No.", Command."Vendor No.");
        DraftHeader.Validate("OMS Currency Code", Command."Currency Code");
        DraftHeader.Validate("Location Code", Command."Location Code");
        DraftHeader.Validate("Expected Receipt Date", Command."Expected Receipt Date");
        DraftHeader.Type := DraftHeader.Type::Checkout;
        DraftHeader.Status := DraftHeader.Status::Open;
        DraftHeader.Validate("Released Date", Today);
        if Command."Created By User ID" <> '' then
            DraftHeader."Created By User ID" := Command."Created By User ID";
        DraftHeader.Insert(true);

        if CommandLine.FindSet() then
            repeat
                Item.Get(CommandLine."Item No.");
                Item.TestField(Blocked, false);
                DraftLine.Init();
                DraftLine."Document No." := DraftHeader."No.";
                DraftLine."Line No." := CommandLine."Line No.";
                DraftLine."Vendor No." := Command."Vendor No.";
                DraftLine."Item No." := CommandLine."Item No.";
                DraftLine.Description := CopyStr(Item.Description, 1, MaxStrLen(DraftLine.Description));
                DraftLine.Validate("TBGC Brand Code", CommandLine."Brand Code");
                DraftLine."Unit of Measure Code" := CommandLine."Unit of Measure Code";
                DraftLine.Quantity := CommandLine.Quantity;
                DraftLine."Direct Unit Cost" := CommandLine."Direct Unit Cost";
                DraftLine.Insert(true);
            until CommandLine.Next() = 0;

        ValidationMgt.ValidateRestrictedItemFamilyMixDraft(DraftHeader."No.");
        ValidationMgt.ValidateDraftLines(DraftHeader."No.", Command."Location Code");

        Command."Draft Order No." := DraftHeader."No.";
        Command."Draft Order Id" := DraftHeader.SystemId;
        Command.Status := Command.Status::Created;
        Command."Completed At" := CurrentDateTime();
        Command.Modify(true);
    end;

    procedure PostReceipt(var Command: Record "OMS2 Receipt Command V2")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPost: Codeunit "Purch.-Post";
        ThresholdMgt: Codeunit "TBGC PO Rcvg Threshold Mgt";
    begin
        Command.LockTable();
        Command.Get(Command."Command Id");
        if Command.Status = Command.Status::Posted then
            exit;

        FindReleasedOrder(Command, PurchaseHeader);
        ApplyQuantities(Command, PurchaseHeader);
        if Command."Posting Date" <> 0D then
            PurchaseHeader.Validate("Posting Date", Command."Posting Date");
        PurchaseHeader.Receive := true;
        PurchaseHeader.Invoice := false;
        PurchaseHeader.Modify(true);
        ThresholdMgt.ValidatePurchaseOrderActualReceiptDates(PurchaseHeader);

        Clear(CapturedReceiptId);
        Clear(CapturedReceiptNo);
        CaptureReceipt := true;
        PurchPost.SetSuppressCommit(true);
        PurchPost.Run(PurchaseHeader);
        CaptureReceipt := false;

        if IsNullGuid(CapturedReceiptId) then
            Error('Business Central posted the receipt but did not return its identity.');

        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Command."Purchase Order No.") then
            ThresholdMgt.ClearActualReceiptDatesAfterReceive(PurchaseHeader);

        Command."Posted Receipt No." := CapturedReceiptNo;
        Command."Posted Receipt Id" := CapturedReceiptId;
        Command.Status := Command.Status::Posted;
        Command."Completed At" := CurrentDateTime();
        Command.Modify(true);
    end;

    local procedure FindReleasedOrder(var Command: Record "OMS2 Receipt Command V2"; var PurchaseHeader: Record "Purchase Header")
    begin
        if not PurchaseHeader.GetBySystemId(Command."Purchase Order Id") then
            Error('The selected purchase order no longer exists.');
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Order);
        if PurchaseHeader.Status <> PurchaseHeader.Status::Released then
            Error('Purchase order %1 must be released before a receipt can be posted.', PurchaseHeader."No.");
        Command."Purchase Order No." := PurchaseHeader."No.";
        Command.Modify(true);
    end;

    local procedure ApplyQuantities(Command: Record "OMS2 Receipt Command V2"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        CommandLine: Record "OMS2 Receipt Command Line V2";
        ActualReceiptDate: Date;
    begin
        CommandLine.SetRange("Command Id", Command."Command Id");
        if CommandLine.IsEmpty() then
            Error('Receipt command %1 has no quantities to receive.', Command."Command Id");

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                if PurchaseLine."Qty. to Receive" <> 0 then begin
                    PurchaseLine.Validate("Qty. to Receive", 0);
                    PurchaseLine.Modify(true);
                end;
            until PurchaseLine.Next() = 0;

        ActualReceiptDate := Command."Posting Date";
        if ActualReceiptDate = 0D then
            ActualReceiptDate := WorkDate();
        if CommandLine.FindSet() then
            repeat
                ReceiveOneLine(CommandLine, PurchaseHeader, ActualReceiptDate);
            until CommandLine.Next() = 0;
    end;

    local procedure ReceiveOneLine(CommandLine: Record "OMS2 Receipt Command Line V2"; PurchaseHeader: Record "Purchase Header"; ActualReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", CommandLine."Item No.");
        if CommandLine."Purchase Line No." <> 0 then
            PurchaseLine.SetRange("Line No.", CommandLine."Purchase Line No.");
        PurchaseLine.SetFilter("Outstanding Quantity", '>%1', 0);
        if not PurchaseLine.FindFirst() then
            Error('Item %1 is not an outstanding line on purchase order %2.', CommandLine."Item No.", PurchaseHeader."No.");
        if CommandLine."Quantity to Receive" > PurchaseLine."Outstanding Quantity" then
            Error('Item %1 has only %2 outstanding on purchase order %3.', CommandLine."Item No.", PurchaseLine."Outstanding Quantity", PurchaseHeader."No.");

        PurchaseLine.Validate("Qty. to Receive", CommandLine."Quantity to Receive");
        PurchaseLine.Validate("TBGC Actual Receipt Date", ActualReceiptDate);
        PurchaseLine.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterInsertReceiptHeader', '', false, false)]
    local procedure CapturePostedReceipt(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
        if not CaptureReceipt then
            exit;
        CapturedReceiptId := PurchRcptHeader.SystemId;
        CapturedReceiptNo := PurchRcptHeader."No.";
    end;

    var
        CaptureReceipt: Boolean;
        CapturedReceiptId: Guid;
        CapturedReceiptNo: Code[20];
}
