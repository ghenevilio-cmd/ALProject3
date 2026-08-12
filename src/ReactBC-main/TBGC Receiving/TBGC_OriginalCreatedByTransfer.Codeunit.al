codeunit 80216 "TBGC Orig Created By Xfer"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC Picking/Receiving - Post", 'OnBeforeInsertUpdatePostedHeader', '', false, false)]
    local procedure PickingReceivingPostOnBeforeInsertUpdatePostedHeader(var CountingHeader: Record "LSC P/R Counting Header"; var PostedHeader: Record "LSC Posted P/R Counting Header")
    begin
        CountingHeader.CalcFields("TBGC Order Date");

        if PostedHeader."TBGC Order Date" <> CountingHeader."TBGC Order Date" then
            PostedHeader."TBGC Order Date" := CountingHeader."TBGC Order Date";

        if PostedHeader."TBGC Original Created By" <> CountingHeader."TBGC Original Created By" then
            PostedHeader."TBGC Original Created By" := CountingHeader."TBGC Original Created By";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterInsertReceiptHeader', '', false, false)]
    local procedure PurchPostOnAfterInsertReceiptHeader(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
        if PurchRcptHeader."TBGC Original Created By" <> '' then
            exit;

        PurchRcptHeader."TBGC Original Created By" := CopyStr(UserId(), 1, MaxStrLen(PurchRcptHeader."TBGC Original Created By"));
        PurchRcptHeader.Modify(false);

        // if not FindRetailReceivingHeader(PurchHeader, CountingHeader) then
        //     exit;

        // PurchRcptHeader."TBGC Original Created By" := CountingHeader."TBGC Original Created By";
        // PurchRcptHeader.Modify(false);
    end;

    local procedure FindRetailReceivingHeader(PurchHeader: Record "Purchase Header"; var CountingHeader: Record "LSC P/R Counting Header"): Boolean
    begin
        CountingHeader.Reset();
        CountingHeader.SetCurrentKey("Counting Type", Receiving, "Reference No.");
        CountingHeader.SetRange("Counting Type", CountingHeader."Counting Type"::Receiving);
        CountingHeader.SetFilter(Receiving, '%1|%2',
          CountingHeader.Receiving::"Purchase Order",
          CountingHeader.Receiving::"Purchase Order(create)");
        CountingHeader.SetRange("Reference No.", PurchHeader."No.");

        if PurchHeader."Location Code" <> '' then
            CountingHeader.SetRange("Location Code", PurchHeader."Location Code");

        if CountingHeader.FindFirst() then
            exit(true);

        if PurchHeader."Location Code" <> '' then begin
            CountingHeader.SetRange("Location Code");
            exit(CountingHeader.FindFirst());
        end;

        exit(false);
    end;
}
