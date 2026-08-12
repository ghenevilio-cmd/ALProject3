codeunit 80271 "TBGC Purchase Brand Transfer"

{
    Permissions = tabledata "Purch. Rcpt. Line" = m;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line Archive", 'OnAfterInsertEvent', '', false, false)]
    local procedure PurchaseLineArchiveOnAfterInsert(var Rec: Record "Purchase Line Archive"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if not PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then
            exit;

        CopyBrandValuesToPurchaseLineArchive(Rec, PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Rcpt. Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure PurchRcptLineOnAfterInsert(var Rec: Record "Purch. Rcpt. Line"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if Rec."Order No." = '' then
            exit;

        if not PurchaseLine.Get(PurchaseLine."Document Type"::Order, Rec."Order No.", Rec."Order Line No.") then
            exit;

        CopyBrandValuesToPurchRcptLine(Rec, PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure PurchInvLineOnAfterInsert(var Rec: Record "Purch. Inv. Line"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if Rec."Order No." = '' then
            exit;

        if not PurchaseLine.Get(PurchaseLine."Document Type"::Order, Rec."Order No.", Rec."Order Line No.") then
            exit;

        CopyBrandValuesToPurchInvLine(Rec, PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnAfterNewPurchRcptLineInsert', '', false, false)]
    local procedure UndoPurchaseReceiptLineOnAfterNewPurchRcptLineInsert(var NewPurchRcptLine: Record "Purch. Rcpt. Line"; OldPurchRcptLine: Record "Purch. Rcpt. Line"; var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var SkipInsertItemEntryRelation: Boolean)
    var
        Modified: Boolean;
    begin
        if NewPurchRcptLine."TBGC Brand Code" <> OldPurchRcptLine."TBGC Brand Code" then begin
            NewPurchRcptLine."TBGC Brand Code" := OldPurchRcptLine."TBGC Brand Code";
            Modified := true;
        end;

        if NewPurchRcptLine."TBGC Original Ordered Qty" <> OldPurchRcptLine."TBGC Original Ordered Qty" then begin
            NewPurchRcptLine."TBGC Original Ordered Qty" := OldPurchRcptLine."TBGC Original Ordered Qty";
            Modified := true;
        end;

        if Modified then
            NewPurchRcptLine.Modify(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Return Shipment Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure ReturnShipmentLineOnAfterInsert(var Rec: Record "Return Shipment Line"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if Rec."Return Order No." = '' then
            exit;

        if not PurchaseLine.Get(PurchaseLine."Document Type"::"Return Order", Rec."Return Order No.", Rec."Return Order Line No.") then
            exit;

        CopyBrandValuesToReturnShipmentLine(Rec, PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure PurchCrMemoLineOnAfterInsert(var Rec: Record "Purch. Cr. Memo Line"; RunTrigger: Boolean)
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        if Rec."Return Shipment No." = '' then
            exit;

        if not ReturnShipmentLine.Get(Rec."Return Shipment No.", Rec."Return Shipment Line No.") then
            exit;

        CopyBrandValuesToPurchCrMemoLine(Rec, ReturnShipmentLine);
    end;

    local procedure CopyBrandValuesToPurchaseLineArchive(var PurchaseLineArchive: Record "Purchase Line Archive"; PurchaseLine: Record "Purchase Line")
    begin
        if PurchaseLineArchive."TBGC Brand Code" = PurchaseLine."TBGC Brand Code" then
            exit;

        PurchaseLineArchive."TBGC Brand Code" := PurchaseLine."TBGC Brand Code";
        PurchaseLineArchive.Modify(false);
    end;

    local procedure CopyBrandValuesToPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line")
    var
        Modified: Boolean;
    begin
        if PurchRcptLine."TBGC Brand Code" <> PurchaseLine."TBGC Brand Code" then begin
            PurchRcptLine."TBGC Brand Code" := PurchaseLine."TBGC Brand Code";
            Modified := true;
        end;

        if PurchRcptLine."TBGC Actual Receipt Date" <> PurchaseLine."TBGC Actual Receipt Date" then begin
            PurchRcptLine."TBGC Actual Receipt Date" := PurchaseLine."TBGC Actual Receipt Date";
            Modified := true;
        end;

        if PurchRcptLine."TBGC Original Ordered Qty" <> PurchaseLine."TBGC Original Ordered Qty" then begin
            PurchRcptLine."TBGC Original Ordered Qty" := PurchaseLine."TBGC Original Ordered Qty";
            Modified := true;
        end;

        if Modified then
            PurchRcptLine.Modify(false);
    end;

    local procedure CopyBrandValuesToPurchInvLine(var PurchInvLine: Record "Purch. Inv. Line"; PurchaseLine: Record "Purchase Line")
    begin
        if PurchInvLine."TBGC Brand Code" = PurchaseLine."TBGC Brand Code" then
            exit;

        PurchInvLine."TBGC Brand Code" := PurchaseLine."TBGC Brand Code";
        PurchInvLine.Modify(false);
    end;

    local procedure CopyBrandValuesToReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line")
    begin
        if ReturnShipmentLine."TBGC Brand Code" = PurchaseLine."TBGC Brand Code" then
            exit;

        ReturnShipmentLine."TBGC Brand Code" := PurchaseLine."TBGC Brand Code";
        ReturnShipmentLine.Modify(false);
    end;

    local procedure CopyBrandValuesToPurchCrMemoLine(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; ReturnShipmentLine: Record "Return Shipment Line")
    begin
        if PurchCrMemoLine."TBGC Brand Code" = ReturnShipmentLine."TBGC Brand Code" then
            exit;

        PurchCrMemoLine."TBGC Brand Code" := ReturnShipmentLine."TBGC Brand Code";
        PurchCrMemoLine.Modify(false);
    end;
}



