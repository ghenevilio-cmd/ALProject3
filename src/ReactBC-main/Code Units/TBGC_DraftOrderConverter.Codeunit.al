codeunit 80210 "TBGC Draft Order Converter"
{
    procedure SetDraftConversionError(DraftOrderNo: Code[20]; ErrorMessage: Text)
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
    begin
        if not DraftOrderHeader.Get(DraftOrderNo) then
            exit;

        DraftOrderHeader."Last Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(DraftOrderHeader."Last Error Message"));
        DraftOrderHeader.Modify(true);
    end;

    procedure ClearDraftConversionError(DraftOrderNo: Code[20])
    begin
        SetDraftConversionError(DraftOrderNo, '');
    end;

    procedure ValidateDraftOrderForPOCreation(DraftOrderNo: Code[20]; EnforceUserAccess: Boolean)
    begin
        ValidateDraftOrderForPOCreationWithPostingDate(DraftOrderNo, EnforceUserAccess, 0D);
    end;

    procedure ValidateDraftOrderForPOCreationWithPostingDate(DraftOrderNo: Code[20]; EnforceUserAccess: Boolean; ManualPostingDate: Date)
    var
        POValidationMgt: Codeunit "TBGC PO Validation Mgt";
        DraftOrderHeader: Record "TBGC Draft Order Header";
        DraftOrderLine: Record "TBGC Draft Order Line";
        VendorNo: Code[20];
        EffectiveLocationCode: Code[20];
    begin
        if not DraftOrderHeader.Get(DraftOrderNo) then
            Error('Draft Order %1 not found.', DraftOrderNo);

        if DraftOrderHeader.Status <> DraftOrderHeader.Status::Open then
            Error('Only Open draft orders can be converted to Purchase Orders.');

        if EnforceUserAccess and DraftOrderHeader."Auto Convert In Progress" then
            Error('Draft Order %1 is currently being processed by auto-convert. Please try again later.', DraftOrderNo);

        if ManualPostingDate = 0D then begin
            if DraftOrderHeader."Released Date" <> Today then
                Error('This Draft Order can only be converted when Released Date is today (%1). Current Released Date is %2.', Today, DraftOrderHeader."Released Date");
        end else begin
            if DraftOrderHeader."Released Date" > Today then
                Error('This Draft Order can only be converted when Released Date is today or earlier. Current Released Date is %1.', DraftOrderHeader."Released Date");
        end;

        DraftOrderLine.SetRange("Document No.", DraftOrderNo);
        if not DraftOrderLine.FindFirst() then
            Error('Draft Order has no line items.');

        VendorNo := DraftOrderLine."Vendor No.";
        EffectiveLocationCode := GetEffectiveLocationCode(DraftOrderHeader."Location Code", EnforceUserAccess);

        ValidateDraftOrder(DraftOrderHeader, EnforceUserAccess, EffectiveLocationCode, ManualPostingDate);
        POValidationMgt.ValidateHeaderBeforeInsert(VendorNo, EffectiveLocationCode, DraftOrderHeader."Expected Receipt Date");
        PreValidatePurchaseHeader(VendorNo, EffectiveLocationCode, DraftOrderHeader."Expected Receipt Date", ManualPostingDate);
        PreValidateAllLines(
          DraftOrderLine,
          VendorNo,
          EffectiveLocationCode,
          DraftOrderHeader."Expected Receipt Date");

        // Manual conversion only. Auto-convert runs under the job queue account, whose
        // permissions are managed separately and must not be judged by the current user's.
        if EnforceUserAccess then
            ValidateBrandTableReadPermission();
    end;

    procedure ConvertDraftOrderToPO(DraftOrderNo: Code[20]; var CreatedPONo: Code[20]; var WarningMessage: Text): Boolean
    begin
        exit(ConvertDraftOrderToPOInternal(DraftOrderNo, 0D, CreatedPONo, WarningMessage, true));
    end;

    procedure ConvertDraftOrderToPOWithPostingDate(DraftOrderNo: Code[20]; ManualPostingDate: Date; var CreatedPONo: Code[20]; var WarningMessage: Text): Boolean
    begin
        exit(ConvertDraftOrderToPOInternal(DraftOrderNo, ManualPostingDate, CreatedPONo, WarningMessage, true));
    end;

    procedure ConvertDraftOrderToPOJobQueue(DraftOrderNo: Code[20]; var CreatedPONo: Code[20]; var WarningMessage: Text): Boolean
    begin
        exit(ConvertDraftOrderToPOInternal(DraftOrderNo, 0D, CreatedPONo, WarningMessage, false));
    end;

    local procedure ConvertDraftOrderToPOInternal(DraftOrderNo: Code[20]; ManualPostingDate: Date; var CreatedPONo: Code[20]; var WarningMessage: Text; EnforceUserAccess: Boolean): Boolean
    var
        DraftConversionContext: Codeunit "TBGC Draft Conversion Context";
        DraftOrderHeader: Record "TBGC Draft Order Header";
        DraftOrderLine: Record "TBGC Draft Order Line";
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PurchLineNo: Integer;
        EffectiveLocationCode: Code[20];
    begin
        if not DraftOrderHeader.Get(DraftOrderNo) then
            Error('Draft Order %1 not found.', DraftOrderNo);

        ClearDraftConversionError(DraftOrderNo);

        DraftOrderLine.SetRange("Document No.", DraftOrderNo);
        DraftOrderLine.FindFirst();
        VendorNo := DraftOrderLine."Vendor No.";
        ValidateDraftOrderForPOCreationWithPostingDate(DraftOrderNo, EnforceUserAccess, ManualPostingDate);
        EffectiveLocationCode := GetEffectiveLocationCode(DraftOrderHeader."Location Code", EnforceUserAccess);

        // Only reached if ALL validations above passed
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader.Insert(true);
        CreatedPONo := PurchHeader."No.";

        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        ApplyManualDocumentDatesToPurchaseHeader(PurchHeader, ManualPostingDate);
        ApplyDraftLocationToPurchaseHeader(PurchHeader, EffectiveLocationCode);
        PurchHeader.Validate("Expected Receipt Date", DraftOrderHeader."Expected Receipt Date");
        PurchHeader."TBGC Draft Order No." := DraftOrderHeader."No.";
        PurchHeader."TBGC Original Created By" := CopyStr(DraftOrderHeader."Created By User ID", 1, MaxStrLen(PurchHeader."TBGC Original Created By"));
        PurchHeader.Modify();

        DraftOrderLine.SetRange("Document No.", DraftOrderNo);
        PurchLineNo := 0;
        if DraftOrderLine.FindSet() then
            repeat
                PurchLineNo += 10000;
                DraftConversionContext.BeginForDocument(PurchHeader."No.", EffectiveLocationCode);
                CreatePurchaseLine(PurchHeader, DraftOrderLine, PurchLineNo, EffectiveLocationCode);
                DraftConversionContext.EndForDocument(PurchHeader."No.");
            until DraftOrderLine.Next() = 0;

        Clear(WarningMessage);
        ClearLastError();
        if not TryReleasePurchaseDocument(PurchHeader) then
            Error(GetLastErrorText());

        DraftOrderHeader.Get(DraftOrderNo);
        DraftOrderHeader.Status := DraftOrderHeader.Status::Converted;
        DraftOrderHeader."Auto Convert In Progress" := false;
        DraftOrderHeader."Auto Convert Started At" := 0DT;
        DraftOrderHeader."Last Error Message" := '';
        DraftOrderHeader.Modify(true);

        exit(true);
    end;

    local procedure ValidateBrandTableReadPermission()
    var
        BrandTableRef: RecordRef;
        BrandTableId: Integer;
        MissingBrandPermissionErr: Label 'You do not have Read permission on table %1, which is required to create the Purchase Order. Ask your administrator to grant access before converting this draft order.';
    begin
        // Checked up front so a missing permission stops the conversion here, before the
        // Purchase Header is inserted. Opened by ID because the table belongs to another app.
        BrandTableId := 60051;

        if not TryOpenTableRef(BrandTableRef, BrandTableId) then
            Error(MissingBrandPermissionErr, BrandTableId);

        if not BrandTableRef.ReadPermission() then begin
            BrandTableRef.Close();
            Error(MissingBrandPermissionErr, BrandTableId);
        end;

        BrandTableRef.Close();
    end;

    [TryFunction]
    local procedure TryOpenTableRef(var TableRef: RecordRef; TableId: Integer)
    begin
        TableRef.Open(TableId);
    end;

    procedure ClaimDraftOrderForAutoConvert(DraftOrderNo: Code[20])
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
    begin
        DraftOrderHeader.LockTable();

        if not DraftOrderHeader.Get(DraftOrderNo) then
            Error('Draft Order %1 not found.', DraftOrderNo);

        if DraftOrderHeader.Status <> DraftOrderHeader.Status::Open then
            Error('Draft Order %1 is no longer open.', DraftOrderNo);

        if DraftOrderHeader."Auto Convert In Progress" then
            Error('Draft Order %1 is already being processed by auto-convert.', DraftOrderNo);

        if DraftOrderHeader."Released Date" <> Today then
            Error('Draft Order %1 is no longer scheduled for today.', DraftOrderNo);

        DraftOrderHeader."Auto Convert In Progress" := true;
        DraftOrderHeader."Auto Convert Started At" := CurrentDateTime();
        DraftOrderHeader.Modify(true);
    end;

    procedure ReleaseDraftAutoConvertClaim(DraftOrderNo: Code[20])
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
    begin
        if not DraftOrderHeader.Get(DraftOrderNo) then
            exit;

        if not DraftOrderHeader."Auto Convert In Progress" then
            exit;

        DraftOrderHeader."Auto Convert In Progress" := false;
        DraftOrderHeader."Auto Convert Started At" := 0DT;
        DraftOrderHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchHeader: Record "Purchase Header"; DraftOrderLine: Record "TBGC Draft Order Line"; LineNo: Integer; EffectiveLocationCode: Code[20])
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        PurchLine.Init();
        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := LineNo;
        PurchLine.Type := PurchLine.Type::Item;
        PurchLine.Validate("No.", DraftOrderLine."Item No.");
        PurchLine."Location Code" := EffectiveLocationCode;
        if DraftOrderLine."TBGC Brand Code" <> '' then
            PurchLine.Validate("TBGC Brand Code", DraftOrderLine."TBGC Brand Code");
        PurchLine.Validate(Quantity, DraftOrderLine.Quantity);
        PurchLine.Validate("Unit of Measure Code", DraftOrderLine."Unit of Measure Code");
        PurchLine.Validate("Direct Unit Cost", DraftOrderLine."Direct Unit Cost");
        PurchLine.Insert(true);
    end;

    local procedure PreValidatePurchaseHeader(VendorNo: Code[20]; LocationCode: Code[20]; ExpectedReceiptDate: Date; ManualPostingDate: Date)
    var
        TempPurchHeader: Record "Purchase Header" temporary;
    begin
        TempPurchHeader.Init();
        TempPurchHeader."Document Type" := TempPurchHeader."Document Type"::Order;
        TempPurchHeader."No." := 'VALIDATION';
        TempPurchHeader.Insert();
        TempPurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        ApplyManualDocumentDatesToPurchaseHeader(TempPurchHeader, ManualPostingDate);
        if TempPurchHeader."Currency Code" <> '' then
            TempPurchHeader.TestField("Currency Factor");
        TempPurchHeader.Validate("Location Code", LocationCode);
        if TempPurchHeader."Shortcut Dimension 1 Code" <> LocationCode then
            TempPurchHeader.Validate("Shortcut Dimension 1 Code", LocationCode);
        ApplyShipmentMethodToPurchaseHeader(TempPurchHeader, LocationCode);
        ApplyLocationShipToDetails(TempPurchHeader, LocationCode);
        TempPurchHeader.Validate("Expected Receipt Date", ExpectedReceiptDate);
    end;

    local procedure ApplyManualDocumentDatesToPurchaseHeader(var PurchHeader: Record "Purchase Header"; ManualPostingDate: Date)
    begin
        if ManualPostingDate = 0D then
            exit;

        PurchHeader.Validate("Posting Date", ManualPostingDate);
        PurchHeader.Validate("Document Date", ManualPostingDate);
    end;

    local procedure ApplyDraftLocationToPurchaseHeader(var PurchHeader: Record "Purchase Header"; DraftLocationCode: Code[20])
    begin
        PurchHeader."Location Code" := DraftLocationCode;
        if PurchHeader."Shortcut Dimension 1 Code" <> DraftLocationCode then
            PurchHeader.Validate("Shortcut Dimension 1 Code", DraftLocationCode);
        ApplyShipmentMethodToPurchaseHeader(PurchHeader, DraftLocationCode);
        ApplyLocationShipToDetails(PurchHeader, DraftLocationCode);
    end;

    local procedure ApplyShipmentMethodToPurchaseHeader(var PurchHeader: Record "Purchase Header"; DraftLocationCode: Code[20])
    var
        ShipmentMethod: Record "Shipment Method";
        ShipmentMethodCode: Code[10];
    begin
        ShipmentMethodCode := CopyStr(DraftLocationCode, 1, MaxStrLen(ShipmentMethodCode));
        if ShipmentMethodCode = '' then
            exit;

        if not ShipmentMethod.Get(ShipmentMethodCode) then
            Error(
              'Shipment Method Code %1 is not set up. Draft conversion stopped before creating a PO.',
              ShipmentMethodCode);

        PurchHeader.Validate("Shipment Method Code", ShipmentMethodCode);
    end;

    local procedure ApplyLocationShipToDetails(var PurchHeader: Record "Purchase Header"; LocationCode: Code[20])
    var
        Location: Record Location;
    begin
        if (LocationCode = '') or (not Location.Get(LocationCode)) then
            exit;

        PurchHeader."Ship-to Name" := Location.Name;
        PurchHeader."Ship-to Name 2" := Location."Name 2";
        PurchHeader."Ship-to Address" := Location.Address;
        PurchHeader."Ship-to Address 2" := Location."Address 2";
        PurchHeader."Ship-to City" := Location.City;
        PurchHeader."Ship-to County" := Location.County;
        PurchHeader."Ship-to Post Code" := Location."Post Code";
        PurchHeader."Ship-to Country/Region Code" := Location."Country/Region Code";
        PurchHeader."Ship-to Contact" := Location.Contact;
    end;

    local procedure ValidateDraftOrder(DraftOrderHeader: Record "TBGC Draft Order Header"; EnforceUserAccess: Boolean; EffectiveLocationCode: Code[20]; ManualPostingDate: Date)
    var
        POValidationMgt: Codeunit "TBGC PO Validation Mgt";
        DraftOrderLine: Record "TBGC Draft Order Line";
    begin
        if DraftOrderHeader."Expected Receipt Date" = 0D then
            Error('Expected Receipt Date is required.');

        if DraftOrderHeader."Expected Receipt Date" < Today then
            Error('Expected Receipt Date cannot be earlier than today.');

        if DraftOrderHeader."Released Date" = 0D then
            Error('Released Date is required.');

        if (ManualPostingDate = 0D) and (DraftOrderHeader."Released Date" < Today) then
            Error('Released Date cannot be earlier than today.');

        if DraftOrderHeader."Location Code" = '' then
            Error('Location Code is required.');

        POValidationMgt.ValidateLocationDimension(DraftOrderHeader."Location Code", 'Draft conversion stopped before creating a PO.');

        if EnforceUserAccess and (not UserCanConvertLocation(DraftOrderHeader."Location Code")) then
            Error(
              'You cannot convert Draft Order %1 because location %2 is not assigned to you through Retail User or Template Master concept setup.',
              DraftOrderHeader."No.",
              DraftOrderHeader."Location Code");

        DraftOrderLine.SetRange("Document No.", DraftOrderHeader."No.");
        if DraftOrderLine.IsEmpty() then
            Error('Draft Order has no line items.');

        POValidationMgt.ValidateRestrictedItemFamilyMixDraft(DraftOrderHeader."No.");
        POValidationMgt.ValidateDraftLines(DraftOrderHeader."No.", EffectiveLocationCode);
    end;

    local procedure UserCanConvertLocation(LocationCode: Code[20]): Boolean
    var
        RetailUser: Record "LSC Retail User";
        Store: Record "LSC Store";
        Concept: Record "TBGC Concept Table";
    begin
        if LocationCode = '' then
            exit(false);

        if RetailUser.Get(UserId()) and (RetailUser."Location Code" = LocationCode) then
            exit(true);

        Store.SetRange("Location Code", LocationCode);
        if not Store.FindFirst() then
            exit(false);

        if Store."TBGC Concept Code" = '' then
            exit(false);

        Concept.SetRange("Concept Code", Store."TBGC Concept Code");
        Concept.SetRange("Template Master", CopyStr(UserId(), 1, MaxStrLen(Concept."Template Master")));
        exit(not Concept.IsEmpty());
    end;

    local procedure GetEffectiveLocationCode(DraftLocationCode: Code[20]; EnforceUserAccess: Boolean): Code[20]
    var
        RetailUser: Record "LSC Retail User";
        Concept: Record "TBGC Concept Table";
    begin
        // Auto convert (job queue) → always use draft's location
        if not EnforceUserAccess then
            exit(DraftLocationCode);

        // 1st PRIORITY: Template Master → use draft's location regardless of retail user setup
        Concept.SetRange("Template Master", CopyStr(UserId(), 1, MaxStrLen(Concept."Template Master")));
        if not Concept.IsEmpty() then
            exit(DraftLocationCode);

        // 2nd PRIORITY: Regular Retail User → use their assigned location
        if RetailUser.Get(UserId()) and (RetailUser."Location Code" <> '') then
            exit(RetailUser."Location Code");

        // Fallback → draft's location
        exit(DraftLocationCode);
    end;

    [TryFunction]
    local procedure TryReleasePurchaseDocument(var PurchHeader: Record "Purchase Header")
    var
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        ReleasePurchaseDocument.PerformManualRelease(PurchHeader);
    end;

    local procedure PreValidateAllLines(var DraftOrderLine: Record "TBGC Draft Order Line"; VendorNo: Code[20]; EffectiveLocationCode: Code[20]; ExpectedReceiptDate: Date)
    var
        TempPurchHeader: Record "Purchase Header" temporary;
        Item: Record Item;
    begin
        TempPurchHeader.Init();
        TempPurchHeader."Document Type" := TempPurchHeader."Document Type"::Order;
        TempPurchHeader."No." := 'VALIDATION';
        TempPurchHeader.Insert();
        TempPurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        ApplyDraftLocationToPurchaseHeader(TempPurchHeader, EffectiveLocationCode);
        TempPurchHeader.Validate("Expected Receipt Date", ExpectedReceiptDate);

        if DraftOrderLine.FindSet() then
            repeat
                if not Item.Get(DraftOrderLine."Item No.") then
                    Error('Item %1 does not exist on line %2.', DraftOrderLine."Item No.", DraftOrderLine."Line No.");

                if Item.Blocked then
                    Error('Item %1 on line %2 is blocked and cannot be converted.', DraftOrderLine."Item No.", DraftOrderLine."Line No.");

                if DraftOrderLine.Quantity <= 0 then
                    Error('Quantity must be greater than 0 on line %1.', DraftOrderLine."Line No.");


                if DraftOrderLine."Unit of Measure Code" = '' then
                    Error('Unit of Measure is required on line %1.', DraftOrderLine."Line No.");
            until DraftOrderLine.Next() = 0;
    end;

}
