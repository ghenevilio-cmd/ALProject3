table 80266 "Approved Product List"
{
    Caption = 'Approved Product List';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }

        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";

            trigger OnValidate()
            begin
                ValidateVendorIsAllowed();
            end;
        }

        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                UpdateItemFamilyDetails();
                ValidateItemIsAllowed();
                ValidateAllowedItemFamily();
            end;
        }

        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }

        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                Inactive := "Ending Date" <> 0D;

                if not Inactive then begin
                    EnsureCurrentUserCanReactivate();
                    "Starting Date" := Today;
                end;
            end;
        }

        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
            Editable = false;
            trigger OnValidate()
            begin
            end;
        }

        field(7; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                PurchasesPayablesSetup: Record "Purchases & Payables Setup";
                PriceChangeRequiresEndingDateErr: Label 'You cannot change Direct Unit Cost while Ending Date is blank. End the current Approved Product List line first, then create a new line with the updated price.';
            begin
                if xRec."Entry No." = 0 then
                    exit;

                if "Direct Unit Cost" = xRec."Direct Unit Cost" then
                    exit;

                if xRec."Direct Unit Cost" = 0 then
                    exit;

                PurchasesPayablesSetup.Get();
                if PurchasesPayablesSetup."APL Require End Date Price Chg" and ("Ending Date" = 0D) then
                    Error(PriceChangeRequiresEndingDateErr);
            end;
        }

        field(8; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }

        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }

        field(10; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }

        field(11; "TBGC Brand Code"; Code[20])
        {
            Caption = 'TBGC Brand Code';
            TableRelation = "TBGC Brand List"."TBGC Brand Code" WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                BrandList: Record "TBGC Brand List";
                TBGCBrands: Record "TBGC Brands";
            begin
                if "TBGC Brand Code" = '' then begin
                    "TBGC Brand Description" := '';
                    "Unit of Measure Code" := '';
                    exit;
                end;

                BrandList.Reset();
                BrandList.SetRange("Item No.", "Item No.");
                BrandList.SetRange("TBGC Brand Code", "TBGC Brand Code");

                if BrandList.FindFirst() then begin
                    "TBGC Brand Description" := BrandList."TBGC Brand Description";
                end else begin
                    "TBGC Brand Description" := '';
                end;

                if TBGCBrands.Get("TBGC Brand Code") then
                    "Unit of Measure Code" := TBGCBrands."Unit of Measure Code"
                else
                    "Unit of Measure Code" := '';
            end;
        }

        field(12; "TBGC Brand Description"; Text[100])
        {
            Caption = 'TBGC Brand Description';
            Editable = false;
        }

        field(13; Inactive; Boolean)
        {
            Caption = 'Inactive';
            ToolTip = 'Indicates whether the purchase price record is active. Inactive records will not be used for purchasing transactions.';

            trigger OnValidate()
            begin
                if Inactive then
                    "Ending Date" := Today
                else begin
                    EnsureCurrentUserCanReactivate();
                    "Ending Date" := 0D;
                    "Starting Date" := Today;
                end;
            end;
        }

        field(14; "TBGC Zoning Code"; Code[20])
        {
            Caption = 'Zoning Code';
            TableRelation = "TBGC Zoning Table"."Zoning Code";

            trigger OnValidate()
            begin
            end;
        }
        field(15; "TBGC Concept Code"; Code[20])
        {
            Caption = 'Concept Code';
            TableRelation = "TBGC Concept Table"."Concept Code";

            trigger OnValidate()
            begin
            end;
        }
        field(16; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
        }

        field(17; "Item Family Code"; Code[20])
        {
            Caption = 'Item Family Code';
            Editable = false;
            TableRelation = "LSC Item Family";
        }

        field(18; "Delivery Lead Time (Days)"; Integer)
        {
            Caption = 'Delivery Lead Time (Days)';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Not used anymore';
            ObsoleteTag = '1.0.0.4';
        }
        field(19; "TBGC City"; Text[50])
        {
            Caption = 'City';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                NormalizeCityValue();
            end;
        }
        field(20; "Modified By"; Code[50])
        {
            Caption = 'Modified By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(21; "Modified At"; DateTime)
        {
            Caption = 'Modified At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(22; "Approved By:"; Text[100])
        {
            Caption = 'Approved By:';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(PriceLookup; "Item No.", "Vendor No.", "Unit of Measure Code", "TBGC Brand Code", "TBGC Zoning Code", "TBGC Concept Code", "TBGC City")
        {
        }
    }

    trigger OnInsert()
    begin
        UpdateItemFamilyDetails();
        ValidateVendorIsAllowed();
        ValidateItemIsAllowed();
        ValidateAllowedItemFamily();
        NormalizeCityValue();
        CheckDuplicatePurchasePrice();
    end;

    trigger OnModify()
    begin
        UpdateItemFamilyDetails();
        ValidateVendorIsAllowed();
        ValidateItemIsAllowed();
        ValidateAllowedItemFamily();
        NormalizeCityValue();
        CheckDuplicatePurchasePrice();
    end;

    local procedure CheckDuplicatePurchasePrice()
    var
        ExistingCustomPurchasePrice: Record "Approved Product List";
        DuplicateCustomPurchasePriceErr: Label 'An active custom purchase price already exists for Vendor No. %1, Item No. %2, Unit of Measure Code %3, Zoning Code %4, Concept Code %5, City %6, Direct Unit Cost %7, Starting Date %8, and Ending Date %9.';
        CurrentCity: Text[50];
    begin
        if Inactive or ("Ending Date" <> 0D) then
            exit;

        if ("Vendor No." = '') or ("Item No." = '') or ("Unit of Measure Code" = '') then
            exit;

        CurrentCity := CopyStr(GetDisplayCityValue(), 1, MaxStrLen(CurrentCity));

        ExistingCustomPurchasePrice.SetRange("Vendor No.", "Vendor No.");
        ExistingCustomPurchasePrice.SetRange("Item No.", "Item No.");
        ExistingCustomPurchasePrice.SetRange("Unit of Measure Code", "Unit of Measure Code");
        ExistingCustomPurchasePrice.SetRange("TBGC Brand Code", "TBGC Brand Code");
        ExistingCustomPurchasePrice.SetRange("TBGC Zoning Code", "TBGC Zoning Code");
        ExistingCustomPurchasePrice.SetRange("TBGC Concept Code", "TBGC Concept Code");
        ExistingCustomPurchasePrice.SetRange("TBGC City", CurrentCity);
        ExistingCustomPurchasePrice.SetRange("Direct Unit Cost", "Direct Unit Cost");
        ExistingCustomPurchasePrice.SetRange("Starting Date", "Starting Date");
        ExistingCustomPurchasePrice.SetRange("Ending Date", "Ending Date");
        ExistingCustomPurchasePrice.SetRange(Inactive, false);

        if "Entry No." <> 0 then
            ExistingCustomPurchasePrice.SetFilter("Entry No.", '<>%1', "Entry No.");

        if ExistingCustomPurchasePrice.FindFirst() then
            Error(
              DuplicateCustomPurchasePriceErr,
              "Vendor No.",
              "Item No.",
              "Unit of Measure Code",
              "TBGC Zoning Code",
              "TBGC Concept Code",
              GetDisplayCityValue(),
              "Direct Unit Cost",
              "Starting Date",
              "Ending Date");
    end;

    local procedure UpdateItemFamilyDetails()
    var
        Item: Record Item;
    begin
        "Item Family Code" := '';

        if "Item No." = '' then
            exit;

        if not Item.Get("Item No.") then
            exit;

        "Item Family Code" := Item."LSC Item Family Code";
    end;

    local procedure ValidateAllowedItemFamily()
    var
        UserSetup: Record "User Setup";
        AllowedFamily: Code[20];
    begin
        if "Item No." = '' then
            exit;

        if "Item Family Code" = '' then
            UpdateItemFamilyDetails();

        // Hard block: MI is never allowed regardless of user setting
        if UpperCase("Item Family Code") = 'MI' then
            Error('Items under Item Family Code MI are not allowed in Approved Product List.');

        // Read the user's Allowed Item Family from Market List Access setup
        if not UserSetup.Get(CopyStr(UserId(), 1, 50)) then
            Error('No User Setup found for the current user. Please contact your administrator.');

        AllowedFamily := UpperCase(UserSetup."TBGC APL Item Family");

        // Blank = fully blocked
        if AllowedFamily = '' then
            Error('You are not allowed to add or edit items in the Approved Product List. Please set an Allowed Item Family in Market List Access for your user.');

        // ALL = no restriction
        if AllowedFamily = 'ALL' then
            exit;

        // Specific family code = must match the item's family
        if UpperCase("Item Family Code") <> AllowedFamily then
            Error('You can only add or edit items with Item Family ''%1'' in the Approved Product List. Item ''%2'' belongs to Item Family ''%3''.', AllowedFamily, "Item No.", "Item Family Code");
    end;

    local procedure ValidateItemIsAllowed()
    var
        Item: Record Item;
    begin
        if "Item No." = '' then
            exit;

        if not Item.Get("Item No.") then
            exit;

        if Item.Blocked then
            Error('Item %1 cannot be used in Approved Product List because it is blocked.', "Item No.");
    end;

    local procedure ValidateVendorIsAllowed()
    var
        Vendor: Record Vendor;
    begin
        if "Vendor No." = '' then
            exit;

        if not Vendor.Get("Vendor No.") then
            exit;

        if Vendor.Blocked in [Vendor.Blocked::All, Vendor.Blocked::Payment] then
            Error(
              'Vendor %1 cannot be used in Approved Product List because it is blocked for %2.',
              "Vendor No.",
              Format(Vendor.Blocked));
    end;

    local procedure NormalizeCityValue()
    begin
        "TBGC City" := CopyStr(UpperCase("TBGC City"), 1, MaxStrLen("TBGC City"));

        if "TBGC City" = '' then
            "TBGC City" := 'ALL';
    end;

    local procedure IsAllCity(CityValue: Text): Boolean
    begin
        CityValue := UpperCase(CityValue);
        exit((CityValue = '') or (CityValue = 'ALL'));
    end;

    local procedure GetDisplayCityValue(): Text
    begin
        if IsAllCity("TBGC City") then
            exit('ALL');

        exit("TBGC City");
    end;

    local procedure EnsureCurrentUserCanReactivate()
    var
        UserSetup: Record "User Setup";
    begin
        if not xRec.Inactive then
            exit;

        if not UserSetup.Get(CopyStr(UserId(), 1, 50)) then
            Error('No User Setup found for the current user. Please contact your administrator.');

        if not UserSetup."TBGC Allowed APL Activation" then
            Error('You are not allowed to reactivate inactive Approved Product List lines.');
    end;

}
