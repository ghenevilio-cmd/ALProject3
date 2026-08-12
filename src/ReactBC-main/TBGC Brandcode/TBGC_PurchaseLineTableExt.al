tableextension 80262 "TBGC Purchase Line Ext" extends "Purchase Line"
{
    fields
    {
        field(80251; "TBGC Brand Code"; Code[20])
        {
            Caption = 'TBGC Brand Code';
            DataClassification = ToBeClassified;
            TableRelation = "TBGC Brand List"."TBGC Brand Code" WHERE("Item No." = FIELD("No."));

            trigger OnValidate()
            begin
                EnsureBrandCodeAllowed();
                UpdateBrandValues();
            end;
        }

        field(80298; "TBGC Actual Receipt Date"; Date)
        {
            Caption = 'Actual Receipt Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                POReceivingThresholdMgt: Codeunit "TBGC PO Rcvg Threshold Mgt";
            begin
                POReceivingThresholdMgt.ValidateActualReceiptDate(Rec);
            end;
        }

        field(80299; "TBGC Original Ordered Qty"; Decimal)
        {
            Caption = 'Original Ordered Qty';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                UpdateBrandValues();
            end;
        }

        modify("Unit of Measure Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateBrandValues();
            end;
        }

        modify(Quantity)
        {
            trigger OnAfterValidate()
            begin
                UpdateBrandValues();
            end;
        }
    }

    local procedure UpdateBrandValues()
    var
        PurchPrice: Record "Approved Product List";
        PurchHeader: Record "Purchase Header";
        BrandList: Record "TBGC Brand List";
        ZoningCode: Code[20];
    begin
        if Type <> Type::Item then begin
            exit;
        end;

        if "No." = '' then begin
            exit;
        end;

        if "TBGC Brand Code" = '' then begin
            exit;
        end;

        BrandList.Reset();
        BrandList.SetRange("Item No.", "No.");
        BrandList.SetRange("TBGC Brand Code", "TBGC Brand Code");
        if BrandList.FindFirst() then
            ApplyBrandDescription(BrandList."TBGC Brand Description");

        if "Document No." = '' then
            exit;

        if not PurchHeader.Get("Document Type", "Document No.") then
            exit;

        if PurchHeader."Buy-from Vendor No." = '' then
            exit;

        ZoningCode := GetPreferredZoningCode(PurchHeader);

        if FindBestPurchasePrice(PurchPrice, PurchHeader."Buy-from Vendor No.", ZoningCode) then
            if ApplyPurchasePrice(PurchPrice) then
                exit;
    end;

    local procedure ApplyBrandDescription(BrandDescription: Text[100])
    begin
        if BrandDescription <> '' then
            Validate(Description, BrandDescription);
    end;

    local procedure ApplyPurchasePrice(PurchPrice: Record "Approved Product List"): Boolean
    begin
        if (PurchPrice."Unit of Measure Code" <> '') and ("Unit of Measure Code" <> PurchPrice."Unit of Measure Code") then begin
            Validate("Unit of Measure Code", PurchPrice."Unit of Measure Code");
            exit(true);
        end;

        ApplyBrandDescription(PurchPrice."TBGC Brand Description");
        Validate("Direct Unit Cost", PurchPrice."Direct Unit Cost");
        exit(true);
    end;

    local procedure GetPreferredZoningCode(PurchHeader: Record "Purchase Header"): Code[20]
    var
        Store: Record "LSC Store";
        LocationCode: Code[20];
    begin
        LocationCode := GetDocumentLocationCode(PurchHeader);

        if LocationCode = '' then
            exit('');

        Store.SetRange("Location Code", LocationCode);
        if Store.FindFirst() then
            exit(Store."TBGC Zoning Code");

        exit('');
    end;

    local procedure FindBestPurchasePrice(var PurchPrice: Record "Approved Product List"; VendorNo: Code[20]; PreferredZoningCode: Code[20]): Boolean
    var
        PurchPriceByUOM: Record "Approved Product List";
        PurchPriceNoZone: Record "Approved Product List";
    begin
        PurchPrice.Reset();
        PurchPrice.SetCurrentKey("Item No.", "Vendor No.", "Unit of Measure Code", "TBGC Brand Code", "TBGC Zoning Code");
        PurchPrice.SetRange(Inactive, false);
        PurchPrice.SetRange("Item No.", "No.");
        PurchPrice.SetRange("Vendor No.", VendorNo);
        PurchPrice.SetRange("TBGC Brand Code", "TBGC Brand Code");

        if PreferredZoningCode <> '' then
            PurchPrice.SetRange("TBGC Zoning Code", PreferredZoningCode);

        if "Unit of Measure Code" <> '' then begin
            PurchPriceByUOM.Copy(PurchPrice);
            PurchPriceByUOM.SetRange("Unit of Measure Code", "Unit of Measure Code");
            if PurchPriceByUOM.FindFirst() then begin
                PurchPrice := PurchPriceByUOM;
                exit(true);
            end;
        end;

        PurchPrice.SetFilter("Unit of Measure Code", '<>%1', '');
        if PurchPrice.FindFirst() then
            exit(true);

        PurchPrice.SetRange("Unit of Measure Code");
        if PurchPrice.FindFirst() then
            exit(true);

        if PreferredZoningCode <> '' then begin
            PurchPriceNoZone.Reset();
            PurchPriceNoZone.SetCurrentKey("Item No.", "Vendor No.", "Unit of Measure Code", "TBGC Brand Code", "TBGC Zoning Code");
            PurchPriceNoZone.SetRange(Inactive, false);
            PurchPriceNoZone.SetRange("Item No.", "No.");
            PurchPriceNoZone.SetRange("Vendor No.", VendorNo);
            PurchPriceNoZone.SetRange("TBGC Brand Code", "TBGC Brand Code");

            if "Unit of Measure Code" <> '' then begin
                PurchPriceByUOM.Copy(PurchPriceNoZone);
                PurchPriceByUOM.SetRange("Unit of Measure Code", "Unit of Measure Code");
                if PurchPriceByUOM.FindFirst() then begin
                    PurchPrice := PurchPriceByUOM;
                    exit(true);
                end;
            end;

            PurchPriceNoZone.SetFilter("Unit of Measure Code", '<>%1', '');
            if PurchPriceNoZone.FindFirst() then begin
                PurchPrice := PurchPriceNoZone;
                exit(true);
            end;

            PurchPriceNoZone.SetRange("Unit of Measure Code");
            if PurchPriceNoZone.FindFirst() then begin
                PurchPrice := PurchPriceNoZone;
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure EnsureBrandCodeAllowed()
    var
        BrandSelectionMgt: Codeunit "TBGC Brand Selection Mgt";
    begin
        if "TBGC Brand Code" = '' then
            exit;

        if not BrandSelectionMgt.IsPurchaseLineBrandAllowed(Rec, "TBGC Brand Code") then
            Error(
              'TBGC Brand Code %1 is not available for item %2, vendor %3, and location %4.',
              "TBGC Brand Code",
              "No.",
              GetBuyFromVendorNo(),
              GetLocationCode());
    end;

    local procedure GetBuyFromVendorNo(): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        if ("Document No." <> '') and PurchHeader.Get("Document Type", "Document No.") then
            exit(PurchHeader."Buy-from Vendor No.");

        exit('');
    end;

    local procedure GetLocationCode(): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        if ("Document No." <> '') and PurchHeader.Get("Document Type", "Document No.") then
            exit(GetDocumentLocationCode(PurchHeader));

        exit('');
    end;

    local procedure GetDocumentLocationCode(PurchHeader: Record "Purchase Header"): Code[20]
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
}

