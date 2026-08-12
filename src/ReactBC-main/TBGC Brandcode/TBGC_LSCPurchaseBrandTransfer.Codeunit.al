codeunit 80290 "TBGC LSC Purch Brand Xfer"
{
    [EventSubscriber(ObjectType::Table, Database::"LSC Picking / Receiving lines", 'OnAfterInsertEvent', '', false, false)]
    local procedure LSCPickingReceivingLinesOnAfterInsert(var Rec: Record "LSC Picking / Receiving lines"; RunTrigger: Boolean)
    begin
        if UpdateBrandValues(Rec) then
            Rec.Modify(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LSC Picking / Receiving lines", 'OnAfterValidateEvent', 'Item No.', false, false)]
    local procedure LSCPickingReceivingLinesOnAfterValidateItemNo(var Rec: Record "LSC Picking / Receiving lines"; var xRec: Record "LSC Picking / Receiving lines")
    begin
        UpdateBrandValues(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LSC Picking / Receiving lines", 'OnAfterValidateEvent', 'Variant Code', false, false)]
    local procedure LSCPickingReceivingLinesOnAfterValidateVariant(var Rec: Record "LSC Picking / Receiving lines"; var xRec: Record "LSC Picking / Receiving lines")
    begin
        UpdateBrandValues(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LSC Picking / Receiving lines", 'OnAfterValidateEvent', 'Description', false, false)]
    local procedure LSCPickingReceivingLinesOnAfterValidateDescription(var Rec: Record "LSC Picking / Receiving lines"; var xRec: Record "LSC Picking / Receiving lines")
    begin
        UpdateBrandValues(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LSC Picking / Receiving lines", 'OnAfterValidateEvent', 'Unit of Measure Code', false, false)]
    local procedure LSCPickingReceivingLinesOnAfterValidateUnitOfMeasure(var Rec: Record "LSC Picking / Receiving lines"; var xRec: Record "LSC Picking / Receiving lines")
    begin
        UpdateBrandValues(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LSC Picking / Receiving lines", 'OnAfterValidateEvent', 'Quantity', false, false)]
    local procedure LSCPickingReceivingLinesOnAfterValidateQuantity(var Rec: Record "LSC Picking / Receiving lines"; var xRec: Record "LSC Picking / Receiving lines")
    begin
        UpdateBrandValues(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC Picking/Receiving Confirm", 'OnBeforeInsertCountLineInMissingLine2', '', false, false)]
    local procedure PickingReceivingConfirmOnBeforeInsertCountLineInMissingLine2(var CountLine: Record "LSC Picking / Receiving lines"; PickReceivLines: Record "LSC Picking / Receiving lines")
    begin
        if CountLine."TBGC Brand Code" = '' then
            CountLine."TBGC Brand Code" := PickReceivLines."TBGC Brand Code";

        if CountLine."TBGC Brand Code" = '' then
            UpdateBrandValues(CountLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC Picking/Receiving Confirm", 'OnBeforeModifyCountingLines', '', false, false)]
    local procedure PickingReceivingConfirmOnBeforeModifyCountingLines(var CountingLines: Record "LSC Picking / Receiving lines"; PickingReceivingLine_L: Record "LSC Picking / Receiving lines")
    begin
        if CountingLines."TBGC Brand Code" = '' then
            CountingLines."TBGC Brand Code" := PickingReceivingLine_L."TBGC Brand Code";

        if CountingLines."TBGC Brand Code" = '' then
            UpdateBrandValues(CountingLines);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC Picking/Receiving - Post", 'OnBeforeInsertReceivingLines', '', false, false)]
    local procedure PickingReceivingPostOnBeforeInsertReceivingLines(var Receivinglines: Record "LSC Picking / Receiving lines"; ReceivinglinesTemp: Record "LSC Picking / Receiving lines" temporary)
    begin
        if Receivinglines."TBGC Brand Code" = '' then
            Receivinglines."TBGC Brand Code" := ReceivinglinesTemp."TBGC Brand Code";

        if Receivinglines."TBGC Brand Code" = '' then
            UpdateBrandValues(Receivinglines);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC Picking/Receiving - Post", 'OnBeforeInsertUpdatePostedLines', '', false, false)]
    local procedure PickingReceivingPostOnBeforeInsertUpdatePostedLines(var CountingLines: Record "LSC Picking / Receiving lines"; var PostedLines: Record "LSC Posted P/R Counting Lines")
    begin
        if PostedLines."TBGC Brand Code" = '' then
            PostedLines."TBGC Brand Code" := CountingLines."TBGC Brand Code";
    end;

    local procedure UpdateBrandValues(var PickingReceivingLine: Record "LSC Picking / Receiving lines"): Boolean
    var
        CountingHeader: Record "LSC P/R Counting Header";
        PurchaseLine: Record "Purchase Line";
        HasChanged: Boolean;
    begin
        if PickingReceivingLine."Item No." = '' then
            exit(false);

        if not CountingHeader.Get(PickingReceivingLine."Document No.") then
            exit(false);

        if (CountingHeader."Counting Type" <> CountingHeader."Counting Type"::Receiving) or
           ((CountingHeader.Receiving <> CountingHeader.Receiving::"Purchase Order") and
            (CountingHeader.Receiving <> CountingHeader.Receiving::"Purchase Order(create)"))
        then
            exit(false);

        if not FindMatchingPurchaseLine(PickingReceivingLine, CountingHeader, PurchaseLine) then
            exit(false);

        if (PickingReceivingLine."TBGC Brand Code" = PurchaseLine."TBGC Brand Code") and
           (PickingReceivingLine.Description = PurchaseLine.Description)
        then
            exit(false);

        if PickingReceivingLine."TBGC Brand Code" <> PurchaseLine."TBGC Brand Code" then begin
            PickingReceivingLine."TBGC Brand Code" := PurchaseLine."TBGC Brand Code";
            HasChanged := true;
        end;

        if (PurchaseLine.Description <> '') and (PickingReceivingLine.Description <> PurchaseLine.Description) then begin
            PickingReceivingLine.Description := PurchaseLine.Description;
            HasChanged := true;
        end;

        exit(HasChanged);
    end;

    local procedure FindMatchingPurchaseLine(PickingReceivingLine: Record "LSC Picking / Receiving lines"; CountingHeader: Record "LSC P/R Counting Header"; var PurchaseLine: Record "Purchase Line"): Boolean
    var
        PurchaseLineByDescription: Record "Purchase Line";
        UniqueBrandCode: Code[20];
        LineCount: Integer;
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", CountingHeader."Reference No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", PickingReceivingLine."Item No.");

        if PickingReceivingLine."Variant Code" <> '' then
            PurchaseLine.SetRange("Variant Code", PickingReceivingLine."Variant Code");

        if not PurchaseLine.FindSet() then
            exit(false);

        repeat
            LineCount += 1;

            if LineCount = 1 then
                UniqueBrandCode := PurchaseLine."TBGC Brand Code"
            else
                if UniqueBrandCode <> PurchaseLine."TBGC Brand Code" then
                    UniqueBrandCode := '*';
        until PurchaseLine.Next() = 0;

        PurchaseLineByDescription.Copy(PurchaseLine);
        PurchaseLineByDescription.SetRange(Description, PickingReceivingLine.Description);
        if PurchaseLineByDescription.FindFirst() then begin
            PurchaseLine := PurchaseLineByDescription;
            exit(true);
        end;

        PurchaseLine.FindFirst();
        if (LineCount = 1) or (UniqueBrandCode <> '*') then
            exit(true);

        exit(false);
    end;
}
