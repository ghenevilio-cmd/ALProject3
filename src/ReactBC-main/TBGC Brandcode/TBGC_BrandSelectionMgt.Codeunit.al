codeunit 80294 "TBGC Brand Selection Mgt"
{
    procedure LookupPurchaseLineBrand(var PurchLine: Record "Purchase Line"): Boolean
    var
        PurchHeader: Record "Purchase Header";
        LookupPage: Page "TBGC Filtered Brand Lookup";
        SelectedPurchPrice: Record "Approved Product List";
        HasChanged: Boolean;
    begin
        if PurchLine."No." = '' then
            Error('Item No. is required before selecting TBGC Brand Code.');

        if PurchLine."Document No." = '' then
            exit(false);

        if not PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.") then
            exit(false);

        if PurchHeader."Buy-from Vendor No." = '' then
            Error('Vendor No. is required before selecting TBGC Brand Code.');

        LookupPage.SetFilters(PurchLine."No.", PurchHeader."Buy-from Vendor No.", GetZoningCode(PurchHeader), GetConceptCode(PurchHeader));
        LookupPage.LookupMode(true);

        if LookupPage.RunModal() <> Action::LookupOK then
            exit(false);

        LookupPage.GetRecord(SelectedPurchPrice);
        if SelectedPurchPrice."TBGC Brand Code" = '' then
            exit(false);

        if (SelectedPurchPrice."Unit of Measure Code" <> '') and
           (PurchLine."Unit of Measure Code" <> SelectedPurchPrice."Unit of Measure Code")
        then begin
            PurchLine.Validate("Unit of Measure Code", SelectedPurchPrice."Unit of Measure Code");
            HasChanged := true;
        end;

        if PurchLine."TBGC Brand Code" <> SelectedPurchPrice."TBGC Brand Code" then begin
            PurchLine.Validate("TBGC Brand Code", SelectedPurchPrice."TBGC Brand Code");
            HasChanged := true;
        end;

        if HasChanged then
            PurchLine.Modify(true);

        exit(true);
    end;

    procedure IsPurchaseLineBrandAllowed(PurchLine: Record "Purchase Line"; BrandCode: Code[20]): Boolean
    var
        PurchHeader: Record "Purchase Header";
        LocationCode: Code[20];
    begin
        if BrandCode = '' then
            exit(true);

        if PurchLine."Document No." = '' then
            exit(true);

        if not PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.") then
            exit(true);

        if PurchHeader."Buy-from Vendor No." = '' then
            exit(true);

        LocationCode := GetLocationCode(PurchHeader);
        exit(IsBrandAllowedForValues(
          PurchLine."No.",
          PurchHeader."Buy-from Vendor No.",
          BrandCode,
          PurchLine."Unit of Measure Code",
          LocationCode));
    end;

    procedure IsBrandAllowedForValues(ItemNo: Code[20]; VendorNo: Code[20]; BrandCode: Code[20]; UnitOfMeasureCode: Code[20]; LocationCode: Code[20]): Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
        ZoningCode: Code[20];
        ConceptCode: Code[20];
        City: Text[50];
    begin
        if BrandCode = '' then
            exit(true);

        if (ItemNo = '') or (VendorNo = '') then
            exit(true);

        TempPurchLine.Init();
        TempPurchLine.Type := TempPurchLine.Type::Item;
        TempPurchLine."No." := ItemNo;
        TempPurchLine."Unit of Measure Code" := UnitOfMeasureCode;

        GetStoreFilters(LocationCode, ZoningCode, ConceptCode, City);
        exit(HasMatchingActivePurchPrice(TempPurchLine, BrandCode, VendorNo, ZoningCode, ConceptCode, City, false, false) or
             HasMatchingActivePurchPrice(TempPurchLine, BrandCode, VendorNo, ZoningCode, ConceptCode, '', false, true) or
             HasMatchingActivePurchPrice(TempPurchLine, BrandCode, VendorNo, ZoningCode, '', '', false, true) or
             HasMatchingActivePurchPrice(TempPurchLine, BrandCode, VendorNo, '', ConceptCode, '', false, true) or
             HasMatchingActivePurchPrice(TempPurchLine, BrandCode, VendorNo, '', '', '', false, true) or
             HasMatchingActivePurchPrice(TempPurchLine, BrandCode, VendorNo, ZoningCode, ConceptCode, City, true, false) or
             HasMatchingActivePurchPrice(TempPurchLine, BrandCode, VendorNo, ZoningCode, ConceptCode, '', true, true) or
             HasMatchingActivePurchPrice(TempPurchLine, BrandCode, VendorNo, ZoningCode, '', '', true, true) or
             HasMatchingActivePurchPrice(TempPurchLine, BrandCode, VendorNo, '', ConceptCode, '', true, true) or
             HasMatchingActivePurchPrice(TempPurchLine, BrandCode, VendorNo, '', '', '', true, true));
    end;

    procedure GetZoningCode(PurchHeader: Record "Purchase Header"): Code[20]
    var
        Store: Record "LSC Store";
        LocationCode: Code[20];
    begin
        LocationCode := GetLocationCode(PurchHeader);
        if LocationCode = '' then
            exit('');

        Store.SetRange("Location Code", LocationCode);
        if Store.FindFirst() then
            exit(Store."TBGC Zoning Code");

        exit('');
    end;

    procedure GetConceptCode(PurchHeader: Record "Purchase Header"): Code[20]
    var
        Store: Record "LSC Store";
        LocationCode: Code[20];
    begin
        LocationCode := GetLocationCode(PurchHeader);
        if LocationCode = '' then
            exit('');

        Store.SetRange("Location Code", LocationCode);
        if Store.FindFirst() then
            exit(Store."TBGC Concept Code");

        exit('');
    end;

    local procedure GetLocationCode(PurchHeader: Record "Purchase Header"): Code[20]
    var
        DraftConversionContext: Codeunit "TBGC Draft Conversion Context";
        ForcedLocationCode: Code[20];
    begin
        if DraftConversionContext.TryGetLocation(PurchHeader."No.", ForcedLocationCode) then
            exit(ForcedLocationCode);

        if PurchHeader."Location Code" <> '' then
            exit(PurchHeader."Location Code");

        exit(PurchHeader."Shortcut Dimension 1 Code");
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

        Store.SetRange("Location Code", LocationCode);
        if not Store.FindFirst() then
            exit;

        ZoningCode := Store."TBGC Zoning Code";
        ConceptCode := Store."TBGC Concept Code";
        City := UpperCase(Store.City);
    end;

    local procedure HasMatchingActivePurchPrice(PurchLine: Record "Purchase Line"; BrandCode: Code[20]; VendorNo: Code[20]; ZoningCode: Code[20]; ConceptCode: Code[20]; City: Text[50]; IgnoreUOM: Boolean; UseGenericCity: Boolean): Boolean
    var
        PurchPrice: Record "Approved Product List";
    begin
        PurchPrice.SetRange(Inactive, false);
        PurchPrice.SetRange("Item No.", PurchLine."No.");
        PurchPrice.SetRange("Vendor No.", VendorNo);
        PurchPrice.SetRange("TBGC Brand Code", BrandCode);

        if not IgnoreUOM then
            if PurchLine."Unit of Measure Code" <> '' then
                PurchPrice.SetRange("Unit of Measure Code", PurchLine."Unit of Measure Code");

        if ZoningCode <> '' then
            PurchPrice.SetRange("TBGC Zoning Code", ZoningCode)
        else
            PurchPrice.SetRange("TBGC Zoning Code", '');

        if ConceptCode <> '' then
            PurchPrice.SetRange("TBGC Concept Code", ConceptCode)
        else
            PurchPrice.SetRange("TBGC Concept Code", '');

        if UseGenericCity then
            PurchPrice.SetFilter("TBGC City", '%1|%2', 'ALL', '')
        else
            if City <> '' then
                PurchPrice.SetRange("TBGC City", City)
            else
                PurchPrice.SetRange("TBGC City", '');

        exit(not PurchPrice.IsEmpty());
    end;
}
