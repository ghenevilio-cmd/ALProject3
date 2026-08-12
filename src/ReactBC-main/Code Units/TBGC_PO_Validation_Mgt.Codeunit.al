codeunit 80212 "TBGC PO Validation Mgt"
{
    procedure ValidateLocationDimension(LocationCode: Code[20]; ErrorPrefix: Text)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        if LocationCode = '' then
            exit;

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Global Dimension 1 Code" = '' then
            exit;

        DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionValue.SetRange(Code, LocationCode);
        if DimensionValue.IsEmpty() then
            Error(
              '%1 Location/BU Code %2 is not set up as a valid dimension value for %3.',
              ErrorPrefix,
              LocationCode,
              GeneralLedgerSetup."Global Dimension 1 Code");
    end;

    procedure ValidateHeaderBeforeInsert(VendorNo: Code[20]; LocationCode: Code[20]; ExpectedReceiptDate: Date)
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Store: Record "LSC Store";
    begin
        if VendorNo = '' then
            Error('Vendor No. is required before creating the Purchase Order header.');

        if not Vendor.Get(VendorNo) then
            Error('Vendor %1 does not exist.', VendorNo);

        if Vendor.Blocked <> Vendor.Blocked::" " then
            Error('Vendor %1 is blocked and cannot be used to create a Purchase Order.', VendorNo);

        if LocationCode = '' then
            Error('Location Code is required before creating the Purchase Order header.');

        if not Location.Get(LocationCode) then
            Error('Location %1 does not exist in the Location table.', LocationCode);

        Store.SetRange("Location Code", LocationCode);
        if Store.IsEmpty() then
            Error('Store setup was not found for location %1.', LocationCode);

        if ExpectedReceiptDate = 0D then
            Error('Expected Receipt Date is required before creating the Purchase Order header.');
    end;

    procedure ValidateRestrictedItemFamilyMixJson(JLines: JsonArray)
    var
        JToken: JsonToken;
        LineToken: JsonToken;
        LineObj: JsonObject;
        ItemNo: Code[20];
        Item: Record Item;
        CurrentItemFamilyCode: Code[20];
        RestrictedItemFamilyCode: Code[20];
        HasOtherItemFamily: Boolean;
        i: Integer;
    begin
        for i := 0 to JLines.Count() - 1 do begin
            JLines.Get(i, LineToken);
            LineObj := LineToken.AsObject();

            Clear(ItemNo);
            if LineObj.Get('itemId', JToken) then
                ItemNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(ItemNo));

            if (ItemNo = '') or (not Item.Get(ItemNo)) then
                continue;

            CurrentItemFamilyCode := UpperCase(Item."LSC Item Family Code");
            ValidateRestrictedFamily(CurrentItemFamilyCode, RestrictedItemFamilyCode, HasOtherItemFamily);
        end;
    end;

    procedure ValidateRestrictedItemFamilyMixDraft(DraftOrderNo: Code[20])
    var
        DraftOrderLine: Record "TBGC Draft Order Line";
        Item: Record Item;
        CurrentItemFamilyCode: Code[20];
        RestrictedItemFamilyCode: Code[20];
        HasOtherItemFamily: Boolean;
    begin
        DraftOrderLine.SetRange("Document No.", DraftOrderNo);
        if not DraftOrderLine.FindSet() then
            exit;

        repeat
            if (DraftOrderLine."Item No." = '') or (not Item.Get(DraftOrderLine."Item No.")) then
                continue;

            CurrentItemFamilyCode := UpperCase(Item."LSC Item Family Code");
            ValidateRestrictedFamily(CurrentItemFamilyCode, RestrictedItemFamilyCode, HasOtherItemFamily);
        until DraftOrderLine.Next() = 0;
    end;

    procedure ValidateCheckoutLines(JLines: JsonArray; LocationCode: Code[20])
    var
        JToken: JsonToken;
        LineToken: JsonToken;
        LineObj: JsonObject;
        Vendor: Record Vendor;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        VendorNo: Code[20];
        ItemNo: Code[20];
        UOMCode: Code[20];
        BrandCode: Code[20];
        Qty: Decimal;
        ZoningCode: Code[20];
        ConceptCode: Code[20];
        City: Text[50];
        i: Integer;
    begin
        GetStoreFilters(LocationCode, ZoningCode, ConceptCode, City);

        for i := 0 to JLines.Count() - 1 do begin
            JLines.Get(i, LineToken);
            LineObj := LineToken.AsObject();

            Clear(VendorNo);
            Clear(ItemNo);
            Clear(UOMCode);
            Clear(BrandCode);
            Clear(Qty);

            if LineObj.Get('vendorNo', JToken) then
                VendorNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(VendorNo));

            if VendorNo = '' then
                Error('Vendor No. missing on one cart line.');

            if not Vendor.Get(VendorNo) then
                Error('Vendor %1 does not exist.', VendorNo);

            if LineObj.Get('itemId', JToken) then
                ItemNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(ItemNo));

            if ItemNo = '' then
                Error('Item No. missing on one cart line.');

            if not Item.Get(ItemNo) then
                Error('Item %1 does not exist.', ItemNo);

            if Item.Blocked then
                Error('Item %1 is blocked and cannot be checked out.', ItemNo);

            if LineObj.Get('uom', JToken) then
                UOMCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(UOMCode));

            if UOMCode <> '' then begin
                ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
                ItemUnitOfMeasure.SetRange(Code, UOMCode);
                if ItemUnitOfMeasure.IsEmpty() then
                    Error('Unit of Measure Code %1 is not set up for Item No. %2.', UOMCode, ItemNo);
            end;

            if LineObj.Get('brandCode', JToken) then
                BrandCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(BrandCode));

            ValidateBrandCode(ItemNo, VendorNo, BrandCode, UOMCode, ZoningCode, ConceptCode, City, LocationCode, 0);

            if LineObj.Get('quantity', JToken) then
                Qty := JToken.AsValue().AsDecimal()
            else
                Qty := 1;

            if Qty <= 0 then
                Error('Quantity must be greater than zero for item %1.', ItemNo);
        end;
    end;

    procedure ValidateDraftLines(DraftOrderNo: Code[20]; LocationCode: Code[20])
    var
        DraftOrderLine: Record "TBGC Draft Order Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        FirstVendorNo: Code[20];
        CurrentVendorNo: Code[20];
        ZoningCode: Code[20];
        ConceptCode: Code[20];
        City: Text[50];
    begin
        DraftOrderLine.SetRange("Document No.", DraftOrderNo);
        if DraftOrderLine.IsEmpty() then
            Error('Draft Order has no line items.');

        GetStoreFilters(LocationCode, ZoningCode, ConceptCode, City);

        if DraftOrderLine.FindSet() then
            repeat
                if DraftOrderLine."Vendor No." = '' then
                    Error('Vendor No. is required on line %1.', DraftOrderLine."Line No.");

                if not Vendor.Get(DraftOrderLine."Vendor No.") then
                    Error('Vendor %1 on line %2 does not exist.', DraftOrderLine."Vendor No.", DraftOrderLine."Line No.");

                CurrentVendorNo := DraftOrderLine."Vendor No.";
                if FirstVendorNo = '' then
                    FirstVendorNo := CurrentVendorNo
                else
                    if CurrentVendorNo <> FirstVendorNo then
                        Error(
                          'Draft Order %1 contains different vendors. Only one vendor is allowed per order.',
                          DraftOrderNo);

                if DraftOrderLine."Item No." = '' then
                    Error('Item No. is required on line %1.', DraftOrderLine."Line No.");

                if not Item.Get(DraftOrderLine."Item No.") then
                    Error('Item %1 on line %2 does not exist.', DraftOrderLine."Item No.", DraftOrderLine."Line No.");

                if Item.Blocked then
                    Error('Item %1 on line %2 is blocked and cannot be converted.', DraftOrderLine."Item No.", DraftOrderLine."Line No.");

                if DraftOrderLine.Quantity <= 0 then
                    Error('Quantity must be greater than 0 on line %1.', DraftOrderLine."Line No.");

                if DraftOrderLine."Unit of Measure Code" = '' then
                    Error('Unit of Measure is required on line %1.', DraftOrderLine."Line No.");

                ItemUnitOfMeasure.SetRange("Item No.", DraftOrderLine."Item No.");
                ItemUnitOfMeasure.SetRange(Code, DraftOrderLine."Unit of Measure Code");
                if ItemUnitOfMeasure.IsEmpty() then
                    Error(
                      'Unit of Measure Code %1 is not set up for Item No. %2 on line %3.',
                      DraftOrderLine."Unit of Measure Code",
                      DraftOrderLine."Item No.",
                      DraftOrderLine."Line No.");

                ValidateBrandCode(
                  DraftOrderLine."Item No.",
                  DraftOrderLine."Vendor No.",
                  DraftOrderLine."TBGC Brand Code",
                  DraftOrderLine."Unit of Measure Code",
                  ZoningCode,
                  ConceptCode,
                  City,
                  LocationCode,
                  DraftOrderLine."Line No.");
            until DraftOrderLine.Next() = 0;
    end;

    local procedure GetStoreFilters(LocationCode: Code[20]; var ZoningCode: Code[20]; var ConceptCode: Code[20]; var City: Text[50])
    var
        Store: Record "LSC Store";
    begin
        Clear(ZoningCode);
        Clear(ConceptCode);
        Clear(City);

        if LocationCode = '' then
            exit;

        if not Store.Get(LocationCode) then
            exit;

        ZoningCode := Store."TBGC Zoning Code";
        ConceptCode := Store."TBGC Concept Code";
        City := UpperCase(Store.City);
    end;

    local procedure ValidateBrandCode(ItemNo: Code[20]; VendorNo: Code[20]; BrandCode: Code[20]; UnitOfMeasureCode: Code[20]; ZoningCode: Code[20]; ConceptCode: Code[20]; City: Text[50]; LocationCode: Code[20]; LineNo: Integer)
    var
        BrandSelectionMgt: Codeunit "TBGC Brand Selection Mgt";
    begin
        if BrandCode = '' then
            exit;

        if BrandSelectionMgt.IsBrandAllowedForValues(ItemNo, VendorNo, BrandCode, UnitOfMeasureCode, LocationCode) then
            exit;

        if LineNo = 0 then
            Error(
              'TBGC Brand Code %1 is not available for item %2, vendor %3, and location %4.',
              BrandCode,
              ItemNo,
              VendorNo,
              LocationCode);

        Error(
          'TBGC Brand Code %1 on line %2 is not available for item %3, vendor %4, and location %5.',
          BrandCode,
          LineNo,
          ItemNo,
          VendorNo,
          LocationCode);
    end;

    local procedure ValidateRestrictedFamily(CurrentItemFamilyCode: Code[20]; var RestrictedItemFamilyCode: Code[20]; var HasOtherItemFamily: Boolean)
    begin
        if CurrentItemFamilyCode = '' then
            exit;

        if CurrentItemFamilyCode in ['OSI', 'SW', 'UF'] then begin
            if HasOtherItemFamily and (RestrictedItemFamilyCode <> CurrentItemFamilyCode) then
                Error('Items under OSI, SW, or UF cannot be ordered together with other item families.');

            if RestrictedItemFamilyCode = '' then
                RestrictedItemFamilyCode := CurrentItemFamilyCode
            else
                if RestrictedItemFamilyCode <> CurrentItemFamilyCode then
                    Error('Items under OSI, SW, or UF cannot be ordered together with other item families.');
        end else begin
            HasOtherItemFamily := true;

            if RestrictedItemFamilyCode <> '' then
                Error('Items under OSI, SW, or UF cannot be ordered together with other item families.');
        end;
    end;
}
