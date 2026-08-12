codeunit 80221 "TBGC Draft Price Update Mgt"
{
    procedure BuildPreview(var PriceUpdateBuffer: Record "TBGC Draft Price Update Buf" temporary)
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
        DraftOrderLine: Record "TBGC Draft Order Line";
        PurchPrice: Record "Approved Product List";
        EntryNo: Integer;
        ZoningCode: Code[20];
        ConceptCode: Code[20];
        City: Text[50];
    begin
        PriceUpdateBuffer.Reset();
        PriceUpdateBuffer.DeleteAll();

        DraftOrderHeader.SetRange(Type, DraftOrderHeader.Type::Draft);
        DraftOrderHeader.SetRange(Status, DraftOrderHeader.Status::Open);
        if not DraftOrderHeader.FindSet() then
            exit;

        repeat
            GetLocationMatchValues(DraftOrderHeader."Location Code", ZoningCode, ConceptCode, City);

            DraftOrderLine.SetRange("Document No.", DraftOrderHeader."No.");
            if DraftOrderLine.FindSet() then
                repeat
                    if not CanUseDraftLine(DraftOrderLine) then
                        continue;

                    if not FindLatestApprovedProductListPrice(DraftOrderLine, ZoningCode, ConceptCode, City, PurchPrice) then
                        continue;

                    if DraftOrderLine."Direct Unit Cost" = PurchPrice."Direct Unit Cost" then
                        continue;

                    EntryNo += 1;
                    InsertPreviewLine(
                      PriceUpdateBuffer,
                      EntryNo,
                      DraftOrderHeader,
                      DraftOrderLine,
                      PurchPrice,
                      ZoningCode,
                      ConceptCode,
                      City);
                until DraftOrderLine.Next() = 0;
        until DraftOrderHeader.Next() = 0;

        PriceUpdateBuffer.Reset();
    end;

    procedure ApplyUpdates(var PriceUpdateBuffer: Record "TBGC Draft Price Update Buf" temporary): Integer
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
        DraftOrderLine: Record "TBGC Draft Order Line";
        PurchPrice: Record "Approved Product List";
        UpdatedCount: Integer;
        ZoningCode: Code[20];
        ConceptCode: Code[20];
        City: Text[50];
    begin
        if not PriceUpdateBuffer.FindSet() then
            exit(0);

        repeat
            if not DraftOrderHeader.Get(PriceUpdateBuffer."Draft Order No.") then
                continue;

            if (DraftOrderHeader.Type <> DraftOrderHeader.Type::Draft) or
               (DraftOrderHeader.Status <> DraftOrderHeader.Status::Open)
            then
                continue;

            if not DraftOrderLine.Get(PriceUpdateBuffer."Draft Order No.", PriceUpdateBuffer."Draft Line No.") then
                continue;

            if not CanUseDraftLine(DraftOrderLine) then
                continue;

            GetLocationMatchValues(DraftOrderHeader."Location Code", ZoningCode, ConceptCode, City);
            if not FindLatestApprovedProductListPrice(DraftOrderLine, ZoningCode, ConceptCode, City, PurchPrice) then
                continue;

            if DraftOrderLine."Direct Unit Cost" = PurchPrice."Direct Unit Cost" then
                continue;

            DraftOrderLine.Validate("Direct Unit Cost", PurchPrice."Direct Unit Cost");
            DraftOrderLine.Modify(true);
            UpdatedCount += 1;
        until PriceUpdateBuffer.Next() = 0;

        exit(UpdatedCount);
    end;

    local procedure InsertPreviewLine(var PriceUpdateBuffer: Record "TBGC Draft Price Update Buf" temporary; EntryNo: Integer; DraftOrderHeader: Record "TBGC Draft Order Header"; DraftOrderLine: Record "TBGC Draft Order Line"; PurchPrice: Record "Approved Product List"; ZoningCode: Code[20]; ConceptCode: Code[20]; City: Text[50])
    begin
        PriceUpdateBuffer.Init();
        PriceUpdateBuffer."Entry No." := EntryNo;
        PriceUpdateBuffer."Draft Order No." := DraftOrderHeader."No.";
        PriceUpdateBuffer."Draft Line No." := DraftOrderLine."Line No.";
        PriceUpdateBuffer."Released Date" := DraftOrderHeader."Released Date";
        PriceUpdateBuffer."Location Code" := DraftOrderHeader."Location Code";
        PriceUpdateBuffer."Vendor No." := DraftOrderLine."Vendor No.";
        PriceUpdateBuffer."Item No." := DraftOrderLine."Item No.";
        PriceUpdateBuffer.Description := DraftOrderLine.Description;
        PriceUpdateBuffer."Unit of Measure Code" := DraftOrderLine."Unit of Measure Code";
        PriceUpdateBuffer."TBGC Brand Code" := DraftOrderLine."TBGC Brand Code";
        PriceUpdateBuffer."TBGC Zoning Code" := ZoningCode;
        PriceUpdateBuffer."TBGC Concept Code" := ConceptCode;
        PriceUpdateBuffer."TBGC City" := City;
        PriceUpdateBuffer."Current Draft Price" := DraftOrderLine."Direct Unit Cost";
        PriceUpdateBuffer."Latest APL Price" := PurchPrice."Direct Unit Cost";
        PriceUpdateBuffer.Difference := PurchPrice."Direct Unit Cost" - DraftOrderLine."Direct Unit Cost";
        PriceUpdateBuffer."APL Starting Date" := PurchPrice."Starting Date";
        PriceUpdateBuffer."APL Entry No." := PurchPrice."Entry No.";
        PriceUpdateBuffer.Insert();
    end;

    local procedure FindLatestApprovedProductListPrice(DraftOrderLine: Record "TBGC Draft Order Line"; ZoningCode: Code[20]; ConceptCode: Code[20]; City: Text[50]; var PurchPrice: Record "Approved Product List"): Boolean
    var
        CandidatePurchPrice: Record "Approved Product List";
        BestPurchPrice: Record "Approved Product List";
        BestScore: Integer;
        CandidateScore: Integer;
        FoundMatch: Boolean;
    begin
        Clear(PurchPrice);
        BestScore := -1;

        CandidatePurchPrice.SetRange(Inactive, false);
        CandidatePurchPrice.SetRange("Vendor No.", DraftOrderLine."Vendor No.");
        CandidatePurchPrice.SetRange("Item No.", DraftOrderLine."Item No.");
        CandidatePurchPrice.SetRange("Unit of Measure Code", CopyStr(DraftOrderLine."Unit of Measure Code", 1, MaxStrLen(CandidatePurchPrice."Unit of Measure Code")));
        CandidatePurchPrice.SetRange("TBGC Brand Code", DraftOrderLine."TBGC Brand Code");

        if not CandidatePurchPrice.FindSet() then
            exit(false);

        repeat
            if not MatchesLocation(CandidatePurchPrice, ZoningCode, ConceptCode, City, CandidateScore) then
                continue;

            if (not FoundMatch) or
               (CandidateScore > BestScore) or
               ((CandidateScore = BestScore) and (CandidatePurchPrice."Starting Date" > BestPurchPrice."Starting Date")) or
               ((CandidateScore = BestScore) and (CandidatePurchPrice."Starting Date" = BestPurchPrice."Starting Date") and (CandidatePurchPrice."Entry No." > BestPurchPrice."Entry No."))
            then begin
                BestPurchPrice := CandidatePurchPrice;
                BestScore := CandidateScore;
                FoundMatch := true;
            end;
        until CandidatePurchPrice.Next() = 0;

        if not FoundMatch then
            exit(false);

        PurchPrice := BestPurchPrice;
        exit(true);
    end;

    local procedure MatchesLocation(PurchPrice: Record "Approved Product List"; ZoningCode: Code[20]; ConceptCode: Code[20]; City: Text[50]; var MatchScore: Integer): Boolean
    begin
        MatchScore := 0;

        if not CodeMatches(PurchPrice."TBGC Zoning Code", ZoningCode, 100, MatchScore) then
            exit(false);

        if not CodeMatches(PurchPrice."TBGC Concept Code", ConceptCode, 10, MatchScore) then
            exit(false);

        if not CityMatches(PurchPrice."TBGC City", City, MatchScore) then
            exit(false);

        exit(true);
    end;

    local procedure CodeMatches(PriceValue: Code[20]; LocationValue: Code[20]; ExactScore: Integer; var MatchScore: Integer): Boolean
    begin
        if PriceValue = '' then
            exit(true);

        if LocationValue = '' then
            exit(false);

        if PriceValue <> LocationValue then
            exit(false);

        MatchScore += ExactScore;
        exit(true);
    end;

    local procedure CityMatches(PriceCity: Text[50]; LocationCity: Text[50]; var MatchScore: Integer): Boolean
    begin
        PriceCity := UpperCase(PriceCity);
        LocationCity := UpperCase(LocationCity);

        if (PriceCity = '') or (PriceCity = 'ALL') then
            exit(true);

        if LocationCity = '' then
            exit(false);

        if PriceCity <> LocationCity then
            exit(false);

        MatchScore += 1;
        exit(true);
    end;

    local procedure GetLocationMatchValues(LocationCode: Code[20]; var ZoningCode: Code[20]; var ConceptCode: Code[20]; var City: Text[50])
    var
        Store: Record "LSC Store";
    begin
        Clear(ZoningCode);
        Clear(ConceptCode);
        Clear(City);

        if LocationCode = '' then
            exit;

        Store.SetRange("Location Code", LocationCode);
        if not Store.FindFirst() then
            exit;

        ZoningCode := Store."TBGC Zoning Code";
        ConceptCode := Store."TBGC Concept Code";
        City := CopyStr(UpperCase(Store.City), 1, MaxStrLen(City));
    end;

    local procedure CanUseDraftLine(DraftOrderLine: Record "TBGC Draft Order Line"): Boolean
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        if (DraftOrderLine."Vendor No." = '') or
           (DraftOrderLine."Item No." = '') or
           (DraftOrderLine."Unit of Measure Code" = '') or
           (DraftOrderLine."TBGC Brand Code" = '')
        then
            exit(false);

        if not Item.Get(DraftOrderLine."Item No.") then
            exit(false);

        if Item.Blocked then
            exit(false);

        if not Vendor.Get(DraftOrderLine."Vendor No.") then
            exit(false);

        if Vendor.Blocked in [Vendor.Blocked::All, Vendor.Blocked::Payment] then
            exit(false);

        exit(true);
    end;
}
