page 80201 "Market List"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Market List';

    layout
    {
        area(Content)
        {
            usercontrol(POS; "POS Control Addin")
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                var
                    DraftOrderMgt: Codeunit "TBGC Draft Order Mgt";
                    MarketListAccessMgt: Codeunit "TBGC Market List Access Mgt";
                    Vendor: Record Vendor;
                    RetailUser: Record "LSC Retail User";
                    OrderHistoryMgt: Codeunit "TBGC APL Order History Mgt";
                    PurchPayablesSetup: Record "Purchases & Payables Setup";
                    OrderingDayMgt: Codeunit "TBGC ML Ordering Day Mgt";
                    SettingsObj: JsonObject;
                    SettingsJson: Text;
                    LocationCode: Code[20];
                    ActiveLocationCode: Code[20];
                begin
                    Clear(LocationCode);
                    Clear(ActiveLocationCode);

                    if CurrentLocationCode <> '' then
                        LocationCode := CurrentLocationCode
                    else begin
                        RetailUser.Reset();
                        RetailUser.SetRange(ID, UserId());
                        if RetailUser.FindFirst() then
                            LocationCode := RetailUser."Location Code";
                    end;

                    if Vendor.FindFirst() then
                        SettingsObj.Add('vendorNo', Vendor."No.")
                    else
                        SettingsObj.Add('vendorNo', '');

                    SettingsObj.Add('isTemplateMaster', IsTemplateMasterUser() or MarketListAccessMgt.IsCurrentUserAllowed());
                    if PurchPayablesSetup.Get() then begin
                        SettingsObj.Add('draftReleasedDateMaxDays', PurchPayablesSetup."APL Draft Rel. Date Max Days");
                        SettingsObj.Add('poReleasingCutOffTime', Format(PurchPayablesSetup."APL PO Releasing Cut Off Time", 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
                    end else begin
                        SettingsObj.Add('draftReleasedDateMaxDays', 0);
                        SettingsObj.Add('poReleasingCutOffTime', '');
                    end;
                    SettingsObj.Add('isOrderingDayAllowed', OrderingDayMgt.IsTodayOrderingDay());
                    SettingsObj.Add('isDraftOrderingDayAllowed', OrderingDayMgt.IsTodayDraftOrderingDay());
                    SettingsObj.Add('allowFromTime', OrderingDayMgt.GetAllowFromTime());
                    SettingsObj.Add('allowToTime', OrderingDayMgt.GetAllowToTime());
                    SettingsObj.Add('draftAllowFromTime', OrderingDayMgt.GetDraftAllowFromTime());
                    SettingsObj.Add('draftAllowToTime', OrderingDayMgt.GetDraftAllowToTime());
                    AddLocationSettings(SettingsObj, LocationCode, ActiveLocationCode);
                    CurrentLocationCode := ActiveLocationCode;
                    SettingsObj.WriteTo(SettingsJson);

                    CurrPage.POS.init(SettingsJson);
                    LoadItemsFromBC(ActiveLocationCode);
                    CurrPage.POS.loadLastOrder(OrderHistoryMgt.GetLatestOrderHistoryJson(ActiveLocationCode));
                    CurrPage.POS.loadDraftSummary(DraftOrderMgt.GetDraftSummaryJson(ActiveLocationCode));
                end;

                trigger OnLocationChanged(LocationCodeText: Text)
                var
                    DraftOrderMgt: Codeunit "TBGC Draft Order Mgt";
                    OrderHistoryMgt: Codeunit "TBGC APL Order History Mgt";
                    LocationCode: Code[20];
                begin
                    LocationCode := CopyStr(LocationCodeText, 1, MaxStrLen(LocationCode));
                    CurrentLocationCode := LocationCode;
                    LoadItemsFromBC(LocationCode);
                    CurrPage.POS.loadLastOrder(OrderHistoryMgt.GetLatestOrderHistoryJson(LocationCode));
                    CurrPage.POS.loadDraftSummary(DraftOrderMgt.GetDraftSummaryJson(LocationCode));
                end;

                trigger OnLoadItemsPage(LocationCodeText: Text; Skip: Integer; Take: Integer; SearchText: Text)
                var
                    LocationCode: Code[20];
                begin
                    LocationCode := CopyStr(LocationCodeText, 1, MaxStrLen(LocationCode));
                    LoadItemsPageFromBC(LocationCode, Skip, Take, SearchText, Skip = 0);
                end;

                trigger OnCreatePurchaseOrder(CartJson: Text)
                var
                    DraftOrderMgt: Codeunit "TBGC Draft Order Mgt";
                    CheckoutState: Codeunit "TBGC POS Checkout State";
                    OrderHistoryMgt: Codeunit "TBGC APL Order History Mgt";
                    CheckoutErrorText: Text;
                    ResultJson: Text;
                    LocationCode: Code[20];
                begin
                    if IsTemplateMasterUser() or IsMarketListAccessUser() then begin
                        CurrPage.POS.OnCheckoutError('You are not allowed to order.');
                        exit;
                    end;

                    ClearLastError();
                    CheckoutState.ClearState();
                    CheckoutState.SetCartJson(CartJson);
                    CheckoutState.SetCheckoutRequest(true);

                    if not Codeunit.Run(Codeunit::"TBGC POS Checkout Runner") then begin
                        CheckoutErrorText := GetLastErrorText();
                        CleanupFailedCheckoutArtifacts(CheckoutState);
                        CheckoutState.ClearState();
                        CurrPage.POS.OnCheckoutError(CheckoutErrorText);
                        exit;
                    end;

                    ResultJson := CheckoutState.GetResultJson();
                    CheckoutState.ClearState();

                    LocationCode := GetLocationCodeFromCartJson(CartJson);
                    CurrPage.POS.loadLastOrder(OrderHistoryMgt.GetLatestOrderHistoryJson(LocationCode));
                    CurrPage.POS.loadDraftSummary(DraftOrderMgt.GetDraftSummaryJson(LocationCode));
                    CurrPage.POS.OnCheckoutSuccess(ResultJson);
                end;

                trigger OnCreateDraftPurchaseOrder(CartJson: Text)
                var
                    DraftOrderMgt: Codeunit "TBGC Draft Order Mgt";
                    CheckoutState: Codeunit "TBGC POS Checkout State";
                    OrderHistoryMgt: Codeunit "TBGC APL Order History Mgt";
                    CheckoutErrorText: Text;
                    ResultJson: Text;
                    LocationCode: Code[20];
                begin
                    ClearLastError();
                    CheckoutState.ClearState();
                    CheckoutState.SetCartJson(CartJson);
                    CheckoutState.SetCheckoutRequest(false);

                    if not Codeunit.Run(Codeunit::"TBGC POS Checkout Runner") then begin
                        CheckoutErrorText := GetLastErrorText();
                        CleanupFailedCheckoutArtifacts(CheckoutState);
                        CheckoutState.ClearState();
                        CurrPage.POS.OnCheckoutError(CheckoutErrorText);
                        exit;
                    end;

                    ResultJson := CheckoutState.GetResultJson();
                    CheckoutState.ClearState();

                    LocationCode := GetLocationCodeFromCartJson(CartJson);
                    CurrPage.POS.loadLastOrder(OrderHistoryMgt.GetLatestOrderHistoryJson(LocationCode));
                    CurrPage.POS.loadDraftSummary(DraftOrderMgt.GetDraftSummaryJson(LocationCode));
                    CurrPage.POS.OnCheckoutSuccess(ResultJson);
                end;

                trigger OnOpenDraftOrders(LocationCodeText: Text)
                begin
                    OpenDraftOrders(CopyStr(LocationCodeText, 1, 20));
                end;

                trigger OnLoadLatestOrderHistory(LocationCodeText: Text)
                var
                    OrderHistoryMgt: Codeunit "TBGC APL Order History Mgt";
                    LocationCode: Code[20];
                    OrderHistoryJson: Text;
                begin
                    LocationCode := CopyStr(LocationCodeText, 1, MaxStrLen(LocationCode));

                    OrderHistoryJson := OrderHistoryMgt.GetValidatedLatestOrderHistoryJson(LocationCode);
                    if OrderHistoryJson = '' then
                        exit;

                    CurrPage.POS.loadOrderHistory(OrderHistoryJson);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BrowseOrderHistory)
            {
                ApplicationArea = All;
                Caption = 'Browse Order History';
                Image = History;

                trigger OnAction()
                begin
                    OpenOrderHistoryLookup();
                end;
            }
            action(RefreshMarketList)
            {
                ApplicationArea = All;
                Caption = 'Refresh Market List';
                Image = Refresh;

                trigger OnAction()
                begin
                    RefreshMarketListData();
                end;
            }
        }
    }

    var
        CurrentLocationCode: Code[20];

    local procedure LoadItemsFromBC(LocationCode: Code[20])
    begin
        LoadItemsPageFromBC(LocationCode, 0, GetMarketListPageSize(), '', true);
    end;

    local procedure LoadItemsPageFromBC(LocationCode: Code[20]; Skip: Integer; Take: Integer; SearchText: Text; ResetItems: Boolean)
    var
        PurchPrice: Record "Approved Product List";
        Store: Record "LSC Store";
        ZoningCode: Code[20];
        ConceptCode: Code[20];
        StoreCity: Text[50];
        AddedPriceKeys: Dictionary of [Text, Boolean];
        JArray: JsonArray;
        PayloadJson: JsonObject;
        ItemsJson: Text;
        AddedCount: Integer;
        MatchedCount: Integer;
        PageSize: Integer;
        StartIndex: Integer;
    begin
        StartIndex := Skip;
        if StartIndex < 0 then
            StartIndex := 0;

        PageSize := Take;
        if PageSize <= 0 then
            PageSize := GetMarketListPageSize();

        if LocationCode <> '' then begin
            if Store.Get(LocationCode) then begin
                ZoningCode := Store."TBGC Zoning Code";
                ConceptCode := Store."TBGC Concept Code";
                StoreCity := CopyStr(UpperCase(Store.City), 1, MaxStrLen(StoreCity));
            end;
        end;

        if (ZoningCode <> '') or (ConceptCode <> '') then begin
            PurchPrice.Reset();
            PurchPrice.SetRange("Inactive", false);
            PurchPrice.SetRange("Ending Date", 0D);

            if ZoningCode <> '' then
                PurchPrice.SetRange("TBGC Zoning Code", ZoningCode);

            if ConceptCode <> '' then
                PurchPrice.SetRange("TBGC Concept Code", ConceptCode);

            if StoreCity <> '' then
                AddPurchPricesToItemsJson(PurchPrice, ZoningCode, ConceptCode, StoreCity, false, SearchText, StartIndex, PageSize, MatchedCount, AddedCount, AddedPriceKeys, JArray);

            if AddedCount < PageSize then
                AddPurchPricesToItemsJson(PurchPrice, ZoningCode, ConceptCode, StoreCity, true, SearchText, StartIndex, PageSize, MatchedCount, AddedCount, AddedPriceKeys, JArray);
        end;

        PayloadJson.Add('items', JArray);
        PayloadJson.Add('skip', StartIndex);
        PayloadJson.Add('take', PageSize);
        PayloadJson.Add('returnedCount', AddedCount);
        PayloadJson.Add('hasMore', AddedCount = PageSize);
        PayloadJson.Add('reset', ResetItems);
        PayloadJson.Add('searchText', SearchText);
        PayloadJson.WriteTo(ItemsJson);
        CurrPage.POS.loadItems(ItemsJson);
    end;

    local procedure AddPurchPricesToItemsJson(BasePurchPrice: Record "Approved Product List"; ZoningCode: Code[20]; ConceptCode: Code[20]; CityValue: Text[50]; UseGenericCity: Boolean; SearchText: Text; Skip: Integer; Take: Integer; var MatchedCount: Integer; var AddedCount: Integer; var AddedPriceKeys: Dictionary of [Text, Boolean]; var JArray: JsonArray)
    var
        PurchPrice: Record "Approved Product List";
    begin
        PurchPrice.Copy(BasePurchPrice);

        if UseGenericCity then
            PurchPrice.SetFilter("TBGC City", '%1|%2', 'ALL', '')
        else
            PurchPrice.SetRange("TBGC City", CityValue);

        if not PurchPrice.FindSet() then
            exit;

        repeat
            AddPurchPriceToItemsJson(PurchPrice, ZoningCode, ConceptCode, CityValue, UseGenericCity, SearchText, Skip, Take, MatchedCount, AddedCount, AddedPriceKeys, JArray);
        until (PurchPrice.Next() = 0) or (AddedCount >= Take);
    end;

    local procedure AddPurchPriceToItemsJson(PurchPrice: Record "Approved Product List"; ZoningCode: Code[20]; ConceptCode: Code[20]; CityValue: Text[50]; UseGenericCity: Boolean; SearchText: Text; Skip: Integer; Take: Integer; var MatchedCount: Integer; var AddedCount: Integer; var AddedPriceKeys: Dictionary of [Text, Boolean]; var JArray: JsonArray)
    var
        Item: Record Item;
        Vendor: Record Vendor;
        UnitOfMeasure: Record "Unit of Measure";
        TenantMedia: Record "Tenant Media";
        ItemFamily: Record "LSC Item Family";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        Base64String: Text;
        UOMDescription: Text;
        ItemFamilyDescription: Text;
        PriceKey: Text;
        JItem: JsonObject;
    begin
        if AddedCount >= Take then
            exit;

        if (PurchPrice."Item No." = '') or (PurchPrice."Vendor No." = '') then
            exit;

        if PurchPrice.Inactive or (PurchPrice."Ending Date" <> 0D) then
            exit;

        if (ZoningCode <> '') and (PurchPrice."TBGC Zoning Code" <> ZoningCode) then
            exit;

        if (ConceptCode <> '') and (PurchPrice."TBGC Concept Code" <> ConceptCode) then
            exit;

        if UseGenericCity then begin
            if (PurchPrice."TBGC City" <> '') and (UpperCase(PurchPrice."TBGC City") <> 'ALL') then
                exit;
        end else
            if UpperCase(PurchPrice."TBGC City") <> UpperCase(CityValue) then
                exit;

        PriceKey := GetPurchPriceMatchKey(PurchPrice);
        if AddedPriceKeys.ContainsKey(PriceKey) then
            exit;

        if not Item.Get(PurchPrice."Item No.") then
            exit;

        if Item.Blocked then
            exit;

        if not Vendor.Get(PurchPrice."Vendor No.") then
            exit;

        if Vendor.Blocked in [Vendor.Blocked::All, Vendor.Blocked::Payment] then
            exit;

        PurchPrice.CalcFields("Vendor Name");

        Clear(UOMDescription);
        if (PurchPrice."Unit of Measure Code" <> '') and UnitOfMeasure.Get(PurchPrice."Unit of Measure Code") then
            UOMDescription := UnitOfMeasure.Description;

        Clear(ItemFamilyDescription);
        if (Item."LSC Item Family Code" <> '') and ItemFamily.Get(Item."LSC Item Family Code") then
            ItemFamilyDescription := ItemFamily.Description;

        if not MarketListItemMatchesSearch(PurchPrice, Item, Vendor, UOMDescription, ItemFamilyDescription, SearchText) then
            exit;

        AddedPriceKeys.Add(PriceKey, true);
        MatchedCount += 1;
        if MatchedCount <= Skip then
            exit;

        Clear(JItem);
        JItem.Add('lineId', Format(PurchPrice.SystemId));
        JItem.Add('id', Item."No.");
        JItem.Add('name', Item.Description);
        JItem.Add('familyCode', Item."LSC Item Family Code");
        JItem.Add('category', ItemFamilyDescription);
        JItem.Add('price', PurchPrice."Direct Unit Cost");
        JItem.Add('vendorNo', PurchPrice."Vendor No.");
        JItem.Add('vendorName', PurchPrice."Vendor Name");
        JItem.Add('vendorMinimumOrderAmount', Vendor."TBGC Minimum Order Amount");
        JItem.Add('brandCode', PurchPrice."TBGC Brand Code");
        JItem.Add('brandDescription', PurchPrice."TBGC Brand Description");
        JItem.Add('uom', PurchPrice."Unit of Measure Code");
        JItem.Add('minimumQuantity', PurchPrice."Minimum Quantity");
        JItem.Add('uomDescription', UOMDescription);

        Base64String := '';
        if Item.Picture.Count > 0 then
            if TenantMedia.Get(Item.Picture.Item(1)) then begin
                TenantMedia.CalcFields(Content);
                if TenantMedia.Content.HasValue then begin
                    TenantMedia.Content.CreateInStream(InStr);
                    Base64String := 'data:' + TenantMedia."Mime Type" + ';base64,' + Base64Convert.ToBase64(InStr);
                end;
            end;

        if Base64String <> '' then
            JItem.Add('imageUrl', Base64String)
        else
            JItem.Add('imageUrl', '');

        JArray.Add(JItem);
        AddedCount += 1;
    end;

    local procedure MarketListItemMatchesSearch(PurchPrice: Record "Approved Product List"; Item: Record Item; Vendor: Record Vendor; UOMDescription: Text; ItemFamilyDescription: Text; SearchText: Text): Boolean
    var
        NormalizedSearchText: Text;
    begin
        NormalizedSearchText := UpperCase(DelChr(SearchText, '<>'));
        if NormalizedSearchText = '' then
            exit(true);

        exit(
          TextContains(Item."No.", NormalizedSearchText) or
          TextContains(Item.Description, NormalizedSearchText) or
          TextContains(PurchPrice."Vendor No.", NormalizedSearchText) or
          TextContains(Vendor.Name, NormalizedSearchText) or
          TextContains(PurchPrice."Vendor Name", NormalizedSearchText) or
          TextContains(PurchPrice."TBGC Brand Code", NormalizedSearchText) or
          TextContains(PurchPrice."TBGC Brand Description", NormalizedSearchText) or
          TextContains(PurchPrice."Unit of Measure Code", NormalizedSearchText) or
          TextContains(UOMDescription, NormalizedSearchText) or
          TextContains(ItemFamilyDescription, NormalizedSearchText));
    end;

    local procedure TextContains(Value: Text; NormalizedSearchText: Text): Boolean
    begin
        exit(StrPos(UpperCase(Value), NormalizedSearchText) > 0);
    end;

    local procedure GetMarketListPageSize(): Integer
    begin
        exit(15);
    end;

    local procedure GetPurchPriceMatchKey(PurchPrice: Record "Approved Product List"): Text
    begin
        exit(
          PurchPrice."Vendor No." + '|' +
          PurchPrice."Item No." + '|' +
          PurchPrice."Unit of Measure Code" + '|' +
          PurchPrice."TBGC Brand Code" + '|' +
          PurchPrice."TBGC Zoning Code" + '|' +
          PurchPrice."TBGC Concept Code" + '|' +
          PurchPrice."TBGC City");
    end;
    local procedure OpenOrderHistoryLookup()
    var
        OrderHistoryLookup: Page "TBGC APL Order Hist. Lookup";
        OrderHistoryMgt: Codeunit "TBGC APL Order History Mgt";
        LocationFilter: Text;
        OrderHistoryJson: Text;
    begin
        LocationFilter := GetOrderHistoryLocationFilter();
        if LocationFilter = '' then
            Error('No Retail User location or Template Master concept location is assigned. You cannot browse order history.');

        OrderHistoryLookup.SetLocationFilter(LocationFilter);
        OrderHistoryLookup.LookupMode(true);
        if OrderHistoryLookup.RunModal() <> Action::LookupOK then begin
            OrderHistoryMgt.ClearSelectedOrderHistory(LocationFilter);
            exit;
        end;

        OrderHistoryJson := OrderHistoryMgt.GetOrderHistoryJsonBySelected(LocationFilter);

        OrderHistoryMgt.ClearSelectedOrderHistory(LocationFilter);
        if OrderHistoryJson = '' then
            exit;

        CurrPage.POS.loadOrderHistory(OrderHistoryJson);
    end;

    local procedure GetOrderHistoryLocationFilter(): Text
    var
        RetailUser: Record "LSC Retail User";
        Concept: Record "TBGC Concept Table";
        Store: Record "LSC Store";
        SeenLocationCodes: Dictionary of [Code[20], Boolean];
        LocationFilter: Text;
        RetailLocationCode: Code[20];
    begin
        if RetailUser.Get(UserId()) and (RetailUser."Location Code" <> '') then
            RetailLocationCode := RetailUser."Location Code";

        Concept.SetRange("Template Master", CopyStr(UserId(), 1, MaxStrLen(Concept."Template Master")));
        if Concept.FindSet() then
            repeat
                Store.Reset();
                Store.SetRange("TBGC Concept Code", Concept."Concept Code");
                if Store.FindSet() then
                    repeat
                        if (Store."Location Code" = '') or SeenLocationCodes.ContainsKey(Store."Location Code") then
                            continue;

                        if LocationFilter = '' then
                            LocationFilter := Store."Location Code"
                        else
                            LocationFilter += '|' + Store."Location Code";

                        SeenLocationCodes.Add(Store."Location Code", true);
                    until Store.Next() = 0;
            until Concept.Next() = 0;

        if LocationFilter <> '' then
            exit(LocationFilter);

        if RetailLocationCode <> '' then
            exit(RetailLocationCode);

        exit(LocationFilter);
    end;

    local procedure GetLocationCodeFromCartJson(CartJson: Text): Code[20]
    var
        JRoot: JsonObject;
        JToken: JsonToken;
        LocationCode: Code[20];
    begin
        if not JRoot.ReadFrom(CartJson) then
            exit('');

        if JRoot.Get('locationCode', JToken) then
            LocationCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(LocationCode));

        exit(LocationCode);
    end;

    local procedure OpenDraftOrders(LocationCode: Code[20])
    var
        DraftOrderMgt: Codeunit "TBGC Draft Order Mgt";
    begin
        DraftOrderMgt.OpenDraftOrdersForLocation(LocationCode);
        LoadItemsFromBC(LocationCode);
        CurrPage.POS.loadDraftSummary(DraftOrderMgt.GetDraftSummaryJson(LocationCode));
    end;

    local procedure RefreshMarketListData()
    var
        DraftOrderMgt: Codeunit "TBGC Draft Order Mgt";
        OrderHistoryMgt: Codeunit "TBGC APL Order History Mgt";
        LocationCode: Code[20];
    begin
        LocationCode := CurrentLocationCode;
        LoadItemsFromBC(LocationCode);
        CurrPage.POS.loadLastOrder(OrderHistoryMgt.GetLatestOrderHistoryJson(LocationCode));
        CurrPage.POS.loadDraftSummary(DraftOrderMgt.GetDraftSummaryJson(LocationCode));
    end;

    local procedure AddLocationSettings(var SettingsObj: JsonObject; DefaultLocationCode: Code[20]; var SelectedLocationCode: Code[20])
    var
        LocationOptions: JsonArray;
        SelectedLocationName: Text;
    begin
        BuildAvailableLocations(LocationOptions, DefaultLocationCode, SelectedLocationCode, SelectedLocationName);

        SettingsObj.Add('locationCode', SelectedLocationCode);
        SettingsObj.Add('locationName', SelectedLocationName);
        SettingsObj.Add('locationOptions', LocationOptions);
    end;

    local procedure BuildAvailableLocations(var LocationOptions: JsonArray; DefaultLocationCode: Code[20]; var SelectedLocationCode: Code[20]; var SelectedLocationName: Text)
    var
        Concept: Record "TBGC Concept Table";
        Store: Record "LSC Store";
        LocationOption: JsonObject;
        SeenLocationCodes: Dictionary of [Code[20], Boolean];
        FallbackStore: Record "LSC Store";
    begin
        Clear(SelectedLocationCode);
        Clear(SelectedLocationName);

        if IsMarketListAccessUser() then begin
            Store.Reset();
            if Store.FindSet() then
                repeat
                    if (Store."Location Code" = '') or SeenLocationCodes.ContainsKey(Store."Location Code") then
                        continue;

                    Clear(LocationOption);
                    LocationOption.Add('code', Store."Location Code");
                    LocationOption.Add('name', Store.Name);
                    LocationOption.Add('label', Store."Location Code" + ' - ' + Store.Name);
                    LocationOptions.Add(LocationOption);
                    SeenLocationCodes.Add(Store."Location Code", true);

                    if (SelectedLocationCode = '') or (Store."Location Code" = DefaultLocationCode) then begin
                        SelectedLocationCode := Store."Location Code";
                        SelectedLocationName := Store.Name;
                    end;
                until Store.Next() = 0;

            exit;
        end;

        Concept.SetRange("Template Master", CopyStr(UserId(), 1, MaxStrLen(Concept."Template Master")));
        if Concept.FindSet() then
            repeat
                Store.Reset();
                Store.SetRange("TBGC Concept Code", Concept."Concept Code");
                if Store.FindSet() then
                    repeat
                        if (Store."Location Code" = '') or SeenLocationCodes.ContainsKey(Store."Location Code") then
                            continue;

                        Clear(LocationOption);
                        LocationOption.Add('code', Store."Location Code");
                        LocationOption.Add('name', Store.Name);
                        LocationOption.Add('label', Store."Location Code" + ' - ' + Store.Name);
                        LocationOptions.Add(LocationOption);
                        SeenLocationCodes.Add(Store."Location Code", true);

                        if (SelectedLocationCode = '') or (Store."Location Code" = DefaultLocationCode) then begin
                            SelectedLocationCode := Store."Location Code";
                            SelectedLocationName := Store.Name;
                        end;
                    until Store.Next() = 0;
            until Concept.Next() = 0;

        if (SelectedLocationCode = '') and (DefaultLocationCode <> '') and FallbackStore.Get(DefaultLocationCode) then begin
            Clear(LocationOption);
            LocationOption.Add('code', FallbackStore."Location Code");
            LocationOption.Add('name', FallbackStore.Name);
            LocationOption.Add('label', FallbackStore."Location Code" + ' - ' + FallbackStore.Name);
            LocationOptions.Add(LocationOption);
            SelectedLocationCode := FallbackStore."Location Code";
            SelectedLocationName := FallbackStore.Name;
        end;
    end;

    local procedure CleanupFailedCheckoutArtifacts(var CheckoutState: Codeunit "TBGC POS Checkout State")
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
        CreatedDraftNos: Text;
        CreatedDraftNo: Code[20];
        SeparatorPosition: Integer;
    begin
        CreatedDraftNos := CheckoutState.GetCreatedDraftNos();
        while CreatedDraftNos <> '' do begin
            SeparatorPosition := StrPos(CreatedDraftNos, '|');
            if SeparatorPosition > 0 then begin
                CreatedDraftNo := CopyStr(CreatedDraftNos, 1, SeparatorPosition - 1);
                CreatedDraftNos := CopyStr(CreatedDraftNos, SeparatorPosition + 1);
            end else begin
                CreatedDraftNo := CopyStr(CreatedDraftNos, 1, MaxStrLen(CreatedDraftNo));
                Clear(CreatedDraftNos);
            end;

            if (CreatedDraftNo <> '') and DraftOrderHeader.Get(CreatedDraftNo) then
                DraftOrderHeader.Delete(true);
        end;
    end;

    local procedure IsTemplateMasterUser(): Boolean
    var
        MarketListAccessMgt: Codeunit "TBGC Market List Access Mgt";
    begin
        exit(MarketListAccessMgt.IsCurrentUserTemplateMaster());
    end;

    local procedure IsMarketListAccessUser(): Boolean
    var
        MarketListAccessMgt: Codeunit "TBGC Market List Access Mgt";
    begin
        exit(MarketListAccessMgt.IsCurrentUserAllowed());
    end;
}

