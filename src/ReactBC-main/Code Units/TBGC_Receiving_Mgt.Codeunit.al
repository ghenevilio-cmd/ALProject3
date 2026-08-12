codeunit 80280 "TBGC Receiving Mgt"
{
    procedure ApplyReceivingModulePOFilters(var PurchHeader: Record "Purchase Header"; SelectedLocationCode: Code[20]): Boolean
    var
        EffectiveLocationCode: Code[20];
    begin
        PurchHeader.Reset();
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetFilter(Status, '%1|%2', PurchHeader.Status::Open, PurchHeader.Status::Released);

        EffectiveLocationCode := ResolveSelectedReceivingLocation(SelectedLocationCode);
        if EffectiveLocationCode = '' then begin
            PurchHeader.SetRange("No.", '');
            exit(false);
        end;

        PurchHeader.SetRange("Shortcut Dimension 1 Code", EffectiveLocationCode);
        exit(true);
    end;

    procedure GetReceivingContextJson(SelectedLocationCode: Code[20]): Text
    var
        ContextJson: JsonObject;
        LocationOptions: JsonArray;
        EffectiveLocationCode: Code[20];
        SelectedLocationName: Text;
        JsonText: Text;
    begin
        BuildAvailableReceivingLocations(LocationOptions, EffectiveLocationCode, SelectedLocationName);
        EffectiveLocationCode := ResolveSelectedReceivingLocationWithOptions(SelectedLocationCode, LocationOptions, EffectiveLocationCode);
        SelectedLocationName := GetLocationNameFromOptions(LocationOptions, EffectiveLocationCode, SelectedLocationName);

        ContextJson.Add('userId', UserId());
        ContextJson.Add('locationCode', EffectiveLocationCode);
        ContextJson.Add('locationName', SelectedLocationName);
        ContextJson.Add('locationOptions', LocationOptions);
        ContextJson.Add('canFilterLocation', CanFilterReceivingLocations());
        ContextJson.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure GetReceivingOrdersJson(SelectedLocationCode: Code[20]): Text
    var
        PayloadJson: JsonObject;
        OrdersToken: JsonToken;
        JsonText: Text;
    begin
        PayloadJson := GetReceivingOrdersPagePayload(SelectedLocationCode, 0, 0, '', 'All', '', '', true);
        PayloadJson.Get('orders', OrdersToken);
        OrdersToken.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure GetReceivingOrdersPageJson(SelectedLocationCode: Code[20]; Skip: Integer; Take: Integer; SearchText: Text; StatusFilter: Text; ReleasedDateFrom: Text; ReleasedDateTo: Text; ResetOrders: Boolean): Text
    var
        PayloadJson: JsonObject;
        JsonText: Text;
    begin
        PayloadJson := GetReceivingOrdersPagePayload(SelectedLocationCode, Skip, Take, SearchText, StatusFilter, ReleasedDateFrom, ReleasedDateTo, ResetOrders);
        PayloadJson.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure GetReceivingOrdersPagePayload(SelectedLocationCode: Code[20]; Skip: Integer; Take: Integer; SearchText: Text; StatusFilter: Text; ReleasedDateFrom: Text; ReleasedDateTo: Text; ResetOrders: Boolean): JsonObject
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchHeader: Record "Purchase Header";
        OrdersArray: JsonArray;
        PayloadJson: JsonObject;
        DisplayStatus: Text;
        ReceivedQty: Decimal;
        RemainingQty: Decimal;
        LastReceiptDate: Date;
        PageSize: Integer;
        StartIndex: Integer;
        MatchedCount: Integer;
        AddedCount: Integer;
        ReleasedOrdersCount: Integer;
        LateReleasedOrdersCount: Integer;
        PartialOrdersCount: Integer;
        FullyReceivedOrdersCount: Integer;
        HasMore: Boolean;
        InitialReceiptDate: Date;
        PartialReceivingVisibilityDays: Integer;
    begin
        PurchasesPayablesSetup.Get();
        PartialReceivingVisibilityDays := PurchasesPayablesSetup."APL Partial Rcvg View Days";
        PageSize := Take;
        if PageSize <= 0 then
            PageSize := 999999;

        StartIndex := Skip;
        if StartIndex < 0 then
            StartIndex := 0;

        ApplyReceivingModulePOFilters(PurchHeader, SelectedLocationCode);

        if PurchHeader.FindSet() then
            repeat
                GetReceivingOrderMetrics(PurchHeader, DisplayStatus, ReceivedQty, RemainingQty, InitialReceiptDate, LastReceiptDate);

                if ReceivingOrderMatchesFilters(PurchHeader, DisplayStatus, SearchText, 'All', ReleasedDateFrom, ReleasedDateTo, InitialReceiptDate, PartialReceivingVisibilityDays) then
                    AddReceivingStatusCount(
                      DisplayStatus,
                      ReleasedOrdersCount,
                      LateReleasedOrdersCount,
                      PartialOrdersCount,
                      FullyReceivedOrdersCount);

                if ReceivingOrderMatchesFilters(PurchHeader, DisplayStatus, SearchText, StatusFilter, ReleasedDateFrom, ReleasedDateTo, InitialReceiptDate, PartialReceivingVisibilityDays) then begin
                    MatchedCount += 1;
                    if MatchedCount > StartIndex then
                        if AddedCount < PageSize then begin
                            AddReceivingOrderToJson(PurchHeader, DisplayStatus, ReceivedQty, RemainingQty, LastReceiptDate, OrdersArray);
                            AddedCount += 1;
                        end else
                            HasMore := true;
                end;
            until PurchHeader.Next() = 0;

        PayloadJson.Add('orders', OrdersArray);
        PayloadJson.Add('skip', StartIndex);
        PayloadJson.Add('take', Take);
        PayloadJson.Add('returnedCount', AddedCount);
        PayloadJson.Add('hasMore', HasMore);
        PayloadJson.Add('reset', ResetOrders);
        PayloadJson.Add('searchText', SearchText);
        PayloadJson.Add('statusFilter', StatusFilter);
        PayloadJson.Add('releasedDateFrom', ReleasedDateFrom);
        PayloadJson.Add('releasedDateTo', ReleasedDateTo);
        PayloadJson.Add('releasedOrdersCount', ReleasedOrdersCount);
        PayloadJson.Add('lateReleasedOrdersCount', LateReleasedOrdersCount);
        PayloadJson.Add('partialOrdersCount', PartialOrdersCount);
        PayloadJson.Add('fullyReceivedOrdersCount', FullyReceivedOrdersCount);
        exit(PayloadJson);
    end;

    local procedure AddReceivingOrderToJson(PurchHeader: Record "Purchase Header"; DisplayStatus: Text; ReceivedQty: Decimal; RemainingQty: Decimal; LastReceiptDate: Date; var OrdersArray: JsonArray)
    var
        OrderObject: JsonObject;
    begin
        OrderObject.Add('documentNo', PurchHeader."No.");
        OrderObject.Add('draftOrderNo', PurchHeader."TBGC Draft Order No.");
        OrderObject.Add('vendorNo', PurchHeader."Buy-from Vendor No.");
        OrderObject.Add('vendorName', PurchHeader."Buy-from Vendor Name");
        OrderObject.Add('status', DisplayStatus);
        OrderObject.Add('orderDate', Format(PurchHeader."Order Date", 0, 9));
        OrderObject.Add('releasedDate', GetReleasedDateText(PurchHeader));
        OrderObject.Add('expectedReceiptDate', Format(PurchHeader."Expected Receipt Date", 0, 9));
        OrderObject.Add('systemModifiedBy', GetUserDisplayName(PurchHeader.SystemModifiedBy));
        OrderObject.Add('systemModifiedAt', FormatDateTimeForJson(PurchHeader.SystemModifiedAt));
        OrderObject.Add('lastReceiptDate', Format(LastReceiptDate, 0, 9));
        OrderObject.Add('receivedQty', ReceivedQty);
        OrderObject.Add('remainingQty', RemainingQty);
        OrderObject.Add('locationCode', PurchHeader."Shortcut Dimension 1 Code");
        OrdersArray.Add(OrderObject);
    end;

    local procedure AddReceivingStatusCount(DisplayStatus: Text; var ReleasedOrdersCount: Integer; var LateReleasedOrdersCount: Integer; var PartialOrdersCount: Integer; var FullyReceivedOrdersCount: Integer)
    begin
        case DisplayStatus of
            'Released':
                ReleasedOrdersCount += 1;
            'Late Released':
                LateReleasedOrdersCount += 1;
            'Partial':
                PartialOrdersCount += 1;
            'Fully Received':
                FullyReceivedOrdersCount += 1;
        end;
    end;

    local procedure ReceivingOrderMatchesFilters(PurchHeader: Record "Purchase Header"; DisplayStatus: Text; SearchText: Text; StatusFilter: Text; ReleasedDateFrom: Text; ReleasedDateTo: Text; InitialReceiptDate: Date; PartialReceivingVisibilityDays: Integer): Boolean
    begin
        if not IsReceivingDisplayStatus(DisplayStatus) then
            exit(false);

        if (DisplayStatus = 'Partial') and (PartialReceivingVisibilityDays > 0) then begin
            if InitialReceiptDate = 0D then
                exit(false);
            if WorkDate() >= InitialReceiptDate + PartialReceivingVisibilityDays then
                exit(false);
        end;

        if (StatusFilter <> '') and (StatusFilter <> 'All') and (DisplayStatus <> StatusFilter) then
            exit(false);

        if not ReceivingOrderMatchesSearch(PurchHeader, SearchText) then
            exit(false);

        exit(ReceivingOrderMatchesReleasedDateFilter(PurchHeader, ReleasedDateFrom, ReleasedDateTo));
    end;

    local procedure IsReceivingDisplayStatus(DisplayStatus: Text): Boolean
    begin
        exit(DisplayStatus in ['Released', 'Late Released', 'Partial', 'Fully Received']);
    end;

    local procedure ReceivingOrderMatchesSearch(PurchHeader: Record "Purchase Header"; SearchText: Text): Boolean
    var
        NormalizedSearchText: Text;
    begin
        NormalizedSearchText := LowerCase(DelChr(SearchText, '<>'));
        if NormalizedSearchText = '' then
            exit(true);

        exit(
          TextContains(PurchHeader."No.", NormalizedSearchText) or
          TextContains(PurchHeader."TBGC Draft Order No.", NormalizedSearchText) or
          TextContains(PurchHeader."Buy-from Vendor No.", NormalizedSearchText) or
          TextContains(PurchHeader."Buy-from Vendor Name", NormalizedSearchText) or
          TextContains(PurchHeader."Shortcut Dimension 1 Code", NormalizedSearchText));
    end;

    local procedure TextContains(Value: Text; NormalizedSearchText: Text): Boolean
    begin
        exit(StrPos(LowerCase(Value), NormalizedSearchText) > 0);
    end;

    local procedure ReceivingOrderMatchesReleasedDateFilter(PurchHeader: Record "Purchase Header"; ReleasedDateFrom: Text; ReleasedDateTo: Text): Boolean
    var
        ReleasedDateText: Text;
    begin
        if (ReleasedDateFrom = '') and (ReleasedDateTo = '') then
            exit(true);

        ReleasedDateText := GetReleasedDateOnlyText(PurchHeader);
        if ReleasedDateText = '' then
            exit(false);

        if (ReleasedDateFrom <> '') and (ReleasedDateText < ReleasedDateFrom) then
            exit(false);

        if (ReleasedDateTo <> '') and (ReleasedDateText > ReleasedDateTo) then
            exit(false);

        exit(true);
    end;

    procedure OpenReceivingDocument(var PurchHeader: Record "Purchase Header"; SelectedLocationCode: Code[20])
    var
        // CountingHeader: Record "LSC P/R Counting Header";
        DisplayStatus: Text;
        ReceivedQty: Decimal;
        RemainingQty: Decimal;
        LastReceiptDate: Date;
        InitialReceiptDate: Date;
    begin
        if PurchHeader."No." = '' then
            exit;

        GetReceivingOrderMetrics(PurchHeader, DisplayStatus, ReceivedQty, RemainingQty, InitialReceiptDate, LastReceiptDate);
        ValidatePurchaseOrderMatchesSelectedLocation(
          PurchHeader,
          CopyStr(GetEffectiveReceivingLocation(SelectedLocationCode, PurchHeader), 1, 10));

        if DisplayStatus = 'Fully Received' then begin
            OpenMarketListPurchaseOrder(PurchHeader, true);
            exit;
        end;

        if PurchHeader.Status = PurchHeader.Status::Released then begin
            // EnsureUserCanReceiveForSelection();
            // CountingHeader := GetOrCreateRetailReceiving(PurchHeader, SelectedLocationCode);
            // Commit();
            // PAGE.RunModal(Page::"LSC Retail Receiving", CountingHeader);
            OpenMarketListPurchaseOrder(PurchHeader, false);
            exit;
        end;

        OpenMarketListPurchaseOrder(PurchHeader, false);
    end;

    local procedure OpenMarketListPurchaseOrder(var PurchHeader: Record "Purchase Header"; ReadOnly: Boolean)
    var
        MarketListReceivingContext: Codeunit "TBGC ML Receiving Context";
    begin
        if not ReadOnly then begin
            RefreshMarketListPostingDate(PurchHeader);
            ResetQtyToReceiveForMarketList(PurchHeader);
            Commit();
            // Re-read after the writes so the page opens on the current row version.
            PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        end;

        MarketListReceivingContext.SetPurchaseOrderNo(PurchHeader."No.", ReadOnly);
        PAGE.RunModal(Page::"Purchase Order", PurchHeader);
        MarketListReceivingContext.ClearPurchaseOrderNo();
    end;

    local procedure ResetQtyToReceiveForMarketList(PurchHeader: Record "Purchase Header"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        Changed: Boolean;
    begin
        PurchaseLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetFilter("Qty. to Receive", '<>%1', 0);

        if PurchaseLine.FindSet(true) then
            repeat
                PurchaseLine.Validate("Qty. to Receive", 0);
                PurchaseLine.Modify(false);
                Changed := true;
            until PurchaseLine.Next() = 0;

        exit(Changed);
    end;

    local procedure RefreshMarketListPostingDate(var PurchHeader: Record "Purchase Header"): Boolean
    begin
        if PurchHeader."Posting Date" = WorkDate() then
            exit(false);

        PurchHeader."Posting Date" := WorkDate();
        PurchHeader.Modify(false);
        exit(true);
    end;

    procedure PrintPurchaseOrder(var PurchHeader: Record "Purchase Header")
    var
        DocumentPrint: Codeunit "Document-Print";
    begin
        if PurchHeader."No." = '' then
            exit;

        DocumentPrint.PrintPurchHeader(PurchHeader);
    end;

    procedure GetCurrentRetailLocation(): Code[20]
    var
        RetailUser: Record "LSC Retail User";
    begin
        RetailUser.Reset();
        RetailUser.SetRange(ID, UserId());
        if RetailUser.FindFirst() then
            exit(RetailUser."Location Code");

        exit('');
    end;

    local procedure CanFilterReceivingLocations(): Boolean
    var
        Concept: Record "TBGC Concept Table";
        MarketListAccessMgt: Codeunit "TBGC Market List Access Mgt";
    begin
        if MarketListAccessMgt.IsCurrentUserAllowed() then
            exit(true);

        Concept.SetRange("Template Master", CopyStr(UserId(), 1, MaxStrLen(Concept."Template Master")));
        exit(not Concept.IsEmpty());
    end;

    local procedure IsTemplateMasterUser(): Boolean
    begin
        exit(CanFilterReceivingLocations());
    end;

    local procedure ResolveSelectedReceivingLocation(SelectedLocationCode: Code[20]): Code[20]
    var
        LocationOptions: JsonArray;
        DefaultLocationCode: Code[20];
        SelectedLocationName: Text;
    begin
        BuildAvailableReceivingLocations(LocationOptions, DefaultLocationCode, SelectedLocationName);
        exit(ResolveSelectedReceivingLocationWithOptions(SelectedLocationCode, LocationOptions, DefaultLocationCode));
    end;

    local procedure BuildAvailableReceivingLocations(var LocationOptions: JsonArray; var SelectedLocationCode: Code[20]; var SelectedLocationName: Text)
    var
        Concept: Record "TBGC Concept Table";
        MarketListAccessMgt: Codeunit "TBGC Market List Access Mgt";
        Store: Record "LSC Store";
        RetailUser: Record "LSC Retail User";
        LocationOption: JsonObject;
        SeenLocationCodes: Dictionary of [Code[20], Boolean];
    begin
        Clear(SelectedLocationCode);
        Clear(SelectedLocationName);

        if MarketListAccessMgt.IsCurrentUserAllowed() then begin
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

                    if SelectedLocationCode = '' then begin
                        SelectedLocationCode := Store."Location Code";
                        SelectedLocationName := Store.Name;
                    end;
                until Store.Next() = 0;
            exit;
        end;

        if CanFilterReceivingLocations() then begin
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

                            if SelectedLocationCode = '' then begin
                                SelectedLocationCode := Store."Location Code";
                                SelectedLocationName := Store.Name;
                            end;
                        until Store.Next() = 0;
                until Concept.Next() = 0;
            exit;
        end;

        RetailUser.SetRange(ID, UserId());
        if RetailUser.FindFirst() and (RetailUser."Location Code" <> '') then begin
            Store.SetRange("Location Code", RetailUser."Location Code");
            if Store.FindFirst() then begin
                Clear(LocationOption);
                LocationOption.Add('code', Store."Location Code");
                LocationOption.Add('name', Store.Name);
                LocationOption.Add('label', Store."Location Code" + ' - ' + Store.Name);
                LocationOptions.Add(LocationOption);
                SelectedLocationCode := Store."Location Code";
                SelectedLocationName := Store.Name;
            end else begin
                Clear(LocationOption);
                LocationOption.Add('code', RetailUser."Location Code");
                LocationOption.Add('name', '');
                LocationOption.Add('label', RetailUser."Location Code");
                LocationOptions.Add(LocationOption);
                SelectedLocationCode := RetailUser."Location Code";
                SelectedLocationName := '';
            end;
        end;
    end;

    local procedure ResolveSelectedReceivingLocationWithOptions(RequestedLocationCode: Code[20]; LocationOptions: JsonArray; DefaultLocationCode: Code[20]): Code[20]
    var
        LocationToken: JsonToken;
        LocationObject: JsonObject;
        LocationValue: JsonToken;
        OptionCode: Code[20];
        i: Integer;
    begin
        if RequestedLocationCode <> '' then
            for i := 0 to LocationOptions.Count() - 1 do begin
                LocationOptions.Get(i, LocationToken);
                LocationObject := LocationToken.AsObject();
                if LocationObject.Get('code', LocationValue) then begin
                    OptionCode := CopyStr(LocationValue.AsValue().AsText(), 1, MaxStrLen(OptionCode));
                    if OptionCode = RequestedLocationCode then
                        exit(OptionCode);
                end;
            end;

        exit(DefaultLocationCode);
    end;

    local procedure GetLocationNameFromOptions(LocationOptions: JsonArray; LocationCode: Code[20]; DefaultLocationName: Text): Text
    var
        LocationToken: JsonToken;
        LocationObject: JsonObject;
        LocationValue: JsonToken;
        OptionCode: Code[20];
        i: Integer;
    begin
        if LocationCode <> '' then
            for i := 0 to LocationOptions.Count() - 1 do begin
                LocationOptions.Get(i, LocationToken);
                LocationObject := LocationToken.AsObject();
                if not LocationObject.Get('code', LocationValue) then
                    continue;

                OptionCode := CopyStr(LocationValue.AsValue().AsText(), 1, MaxStrLen(OptionCode));
                if OptionCode <> LocationCode then
                    continue;

                if LocationObject.Get('name', LocationValue) then
                    exit(LocationValue.AsValue().AsText());
            end;

        exit(DefaultLocationName);
    end;

    local procedure GetCurrentRetailStore(): Code[10]
    var
        RetailUser: Record "LSC Retail User";
    begin
        RetailUser.Reset();
        RetailUser.SetRange(ID, UserId());
        if RetailUser.FindFirst() then
            exit(RetailUser."Store No.");

        exit('');
    end;

    local procedure GetOrCreateRetailReceiving(PurchHeader: Record "Purchase Header"; SelectedLocationCode: Code[20]): Record "LSC P/R Counting Header"
    var
        CountingHeader: Record "LSC P/R Counting Header";
        ExistingCountingHeader: Record "LSC P/R Counting Header";
        StoreNo: Code[10];
        LocationCode: Code[10];
        UseRetailUserFallback: Boolean;
    begin
        LocationCode := GetRetailReceivingLocation(PurchHeader, SelectedLocationCode);
        StoreNo := GetRetailReceivingStoreNo(LocationCode);
        UseRetailUserFallback := ShouldFallbackToRetailUserStore(SelectedLocationCode, PurchHeader);
        if (StoreNo = '') and (LocationCode <> '') then
            Error('No store is mapped to the selected location %1.', LocationCode);

        if (StoreNo = '') and UseRetailUserFallback then
            StoreNo := GetCurrentRetailStore();

        ValidatePurchaseOrderMatchesSelectedLocation(PurchHeader, LocationCode);
        PreValidateRetailReceivingSelection(PurchHeader, StoreNo, LocationCode);

        if FindExistingRetailReceiving(ExistingCountingHeader, PurchHeader."No.", LocationCode) then begin
            ApplyRetailReceivingSelection(ExistingCountingHeader, PurchHeader, StoreNo, LocationCode);
            if ExistingCountingHeader."Reference Name" <> PurchHeader."Buy-from Vendor Name" then
                ExistingCountingHeader."Reference Name" := PurchHeader."Buy-from Vendor Name";
            if ExistingCountingHeader."Vendor No. / Customer No." <> PurchHeader."Buy-from Vendor No." then
                ExistingCountingHeader."Vendor No. / Customer No." := PurchHeader."Buy-from Vendor No.";
            if ExistingCountingHeader."Expected Date" <> PurchHeader."Expected Receipt Date" then
                ExistingCountingHeader."Expected Date" := PurchHeader."Expected Receipt Date";
            if ExistingCountingHeader."TBGC Original Created By" = '' then
                ExistingCountingHeader."TBGC Original Created By" := CopyStr(UserId(), 1, MaxStrLen(ExistingCountingHeader."TBGC Original Created By"));
            ExistingCountingHeader.Modify(true);
            exit(ExistingCountingHeader);
        end;

        Clear(CountingHeader);
        CountingHeader.Init();
        CountingHeader."Counting Type" := CountingHeader."Counting Type"::Receiving;
        CountingHeader.Receiving := CountingHeader.Receiving::"Purchase Order";
        CountingHeader.Type := CountingHeader.Type::Scanned;
        CountingHeader.Insert(true);
        CountingHeader.Get(CountingHeader."No.");
        ApplyRetailReceivingSelection(CountingHeader, PurchHeader, StoreNo, LocationCode);
        CountingHeader."Reference Name" := PurchHeader."Buy-from Vendor Name";
        CountingHeader."Vendor No. / Customer No." := PurchHeader."Buy-from Vendor No.";
        CountingHeader."Expected Date" := PurchHeader."Expected Receipt Date";
        CountingHeader."TBGC Original Created By" := CopyStr(UserId(), 1, MaxStrLen(CountingHeader."TBGC Original Created By"));
        CountingHeader.Modify(true);
        CountingHeader.Get(CountingHeader."No.");

        exit(CountingHeader);
    end;

    local procedure FindExistingRetailReceiving(var ExistingCountingHeader: Record "LSC P/R Counting Header"; PurchaseOrderNo: Code[20]; LocationCode: Code[10]): Boolean
    begin
        ExistingCountingHeader.Reset();
        ExistingCountingHeader.SetCurrentKey("Counting Type", Receiving, "Reference No.");
        ExistingCountingHeader.SetRange("Counting Type", ExistingCountingHeader."Counting Type"::Receiving);
        ExistingCountingHeader.SetRange(Receiving, ExistingCountingHeader.Receiving::"Purchase Order");
        ExistingCountingHeader.SetRange("Reference No.", PurchaseOrderNo);

        if LocationCode <> '' then
            ExistingCountingHeader.SetRange("Location Code", LocationCode);
        exit(ExistingCountingHeader.FindFirst());
    end;

    local procedure GetRetailReceivingLocation(PurchHeader: Record "Purchase Header"; SelectedLocationCode: Code[20]): Code[10]
    var
        RetailLocation: Code[20];
    begin
        RetailLocation := GetEffectiveReceivingLocation(SelectedLocationCode, PurchHeader);
        if RetailLocation <> '' then
            exit(CopyStr(RetailLocation, 1, 10));

        if PurchHeader."Shortcut Dimension 1 Code" <> '' then
            exit(CopyStr(PurchHeader."Shortcut Dimension 1 Code", 1, 10));

        if PurchHeader."Location Code" <> '' then
            exit(CopyStr(PurchHeader."Location Code", 1, 10));

        RetailLocation := ResolveSelectedReceivingLocation(SelectedLocationCode);
        if RetailLocation <> '' then
            exit(CopyStr(RetailLocation, 1, 10));

        RetailLocation := GetCurrentRetailLocation();
        exit(CopyStr(RetailLocation, 1, 10));
    end;


    local procedure ApplyRetailReceivingSelection(var CountingHeader: Record "LSC P/R Counting Header"; PurchHeader: Record "Purchase Header"; StoreNo: Code[10]; LocationCode: Code[10])
    begin
        if StoreNo <> '' then
            CountingHeader.Validate("Store No.", StoreNo);
        if LocationCode <> '' then
            CountingHeader.Validate("Location Code", LocationCode);
        CountingHeader.Validate("Reference No.", PurchHeader."No.");

        if (StoreNo <> '') and (CountingHeader."Store No." <> StoreNo) then
            CountingHeader.Validate("Store No.", StoreNo);
        if (LocationCode <> '') and (CountingHeader."Location Code" <> LocationCode) then
            CountingHeader.Validate("Location Code", LocationCode);
        if CountingHeader."Reference No." <> PurchHeader."No." then
            CountingHeader.Validate("Reference No.", PurchHeader."No.");

        if (CountingHeader."Reference No." <> PurchHeader."No.") or
           ((LocationCode <> '') and (CountingHeader."Location Code" <> LocationCode))
        then
            Error(
              'Retail Receiving mapping failed. Expected PO %1 and location %2, but got PO %3 and location %4.',
              PurchHeader."No.",
              LocationCode,
              CountingHeader."Reference No.",
              CountingHeader."Location Code");
    end;

    local procedure PreValidateRetailReceivingSelection(PurchHeader: Record "Purchase Header"; StoreNo: Code[10]; LocationCode: Code[10])
    var
        TempCountingHeader: Record "LSC P/R Counting Header" temporary;
    begin
        TempCountingHeader.Init();
        TempCountingHeader."No." := 'VALIDATE';
        TempCountingHeader."Counting Type" := TempCountingHeader."Counting Type"::Receiving;
        TempCountingHeader.Receiving := TempCountingHeader.Receiving::"Purchase Order";
        TempCountingHeader.Type := TempCountingHeader.Type::Scanned;
        TempCountingHeader.Insert();

        if StoreNo <> '' then
            TempCountingHeader.Validate("Store No.", StoreNo);
        if LocationCode <> '' then
            TempCountingHeader.Validate("Location Code", LocationCode);
        TempCountingHeader.Validate("Reference No.", PurchHeader."No.");
    end;

    local procedure ValidatePurchaseOrderMatchesSelectedLocation(PurchHeader: Record "Purchase Header"; LocationCode: Code[10])
    var
        PurchaseLocationCode: Code[20];
    begin
        if LocationCode = '' then
            exit;

        if PurchHeader."Shortcut Dimension 1 Code" <> '' then
            PurchaseLocationCode := PurchHeader."Shortcut Dimension 1 Code"
        else
            PurchaseLocationCode := PurchHeader."Location Code";

        if (PurchaseLocationCode <> '') and (CopyStr(PurchaseLocationCode, 1, MaxStrLen(LocationCode)) <> LocationCode) then
            Error(
              'The selected PO %1 belongs to location %2, not the chosen location %3.',
              PurchHeader."No.",
              PurchaseLocationCode,
              LocationCode);
    end;

    local procedure GetEffectiveReceivingLocation(SelectedLocationCode: Code[20]; PurchHeader: Record "Purchase Header"): Code[20]
    var
        EffectiveSelectedLocation: Code[20];
    begin
        EffectiveSelectedLocation := ResolveSelectedReceivingLocation(SelectedLocationCode);

        if IsTemplateMasterUser() then
            exit(EffectiveSelectedLocation);

        if PurchHeader."Shortcut Dimension 1 Code" <> '' then
            exit(PurchHeader."Shortcut Dimension 1 Code");

        if PurchHeader."Location Code" <> '' then
            exit(PurchHeader."Location Code");

        if EffectiveSelectedLocation <> '' then
            exit(EffectiveSelectedLocation);

        exit(GetCurrentRetailLocation());
    end;

    local procedure ShouldFallbackToRetailUserStore(SelectedLocationCode: Code[20]; PurchHeader: Record "Purchase Header"): Boolean
    begin
        if IsTemplateMasterUser() then
            exit(false);

        if SelectedLocationCode <> '' then
            exit(false);

        if (PurchHeader."Shortcut Dimension 1 Code" <> '') or (PurchHeader."Location Code" <> '') then
            exit(false);

        exit(true);
    end;

    local procedure EnsureUserCanReceiveForSelection()
    var
        MarketListAccessMgt: Codeunit "TBGC Market List Access Mgt";
    begin
        if IsTemplateMasterUser() or MarketListAccessMgt.IsCurrentUserAllowed() then
            Error('You are not allowed to receive PO.');
    end;

    local procedure GetRetailReceivingStoreNo(LocationCode: Code[10]): Code[10]
    var
        Store: Record "LSC Store";
        StoreNo: Code[10];
    begin
        if LocationCode = '' then
            exit('');

        Store.SetRange("Location Code", LocationCode);
        if Store.FindFirst() then begin
            StoreNo := Store."No.";
            exit(StoreNo);
        end;

        exit('');
    end;

    local procedure GetReceivingOrderMetrics(PurchHeader: Record "Purchase Header"; var DisplayStatus: Text; var ReceivedQty: Decimal; var RemainingQty: Decimal; var InitialReceiptDate: Date; var LastReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        DisplayStatus := Format(PurchHeader.Status);
        ReceivedQty := 0;
        RemainingQty := 0;
        InitialReceiptDate := 0D;
        LastReceiptDate := 0D;

        PurchaseLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        if PurchaseLine.FindSet() then
            repeat
                ReceivedQty += PurchaseLine."Quantity Received";
                RemainingQty += PurchaseLine."Outstanding Quantity";
            until PurchaseLine.Next() = 0;

        if (ReceivedQty > 0) and (RemainingQty = 0) then
            DisplayStatus := 'Fully Received'
        else
            if (ReceivedQty > 0) and (RemainingQty > 0) then
                DisplayStatus := 'Partial'
            else
                if (PurchHeader.Status = PurchHeader.Status::Released) and IsLateReleased(PurchHeader) then
                    DisplayStatus := 'Late Released';

        PurchRcptLine.SetCurrentKey("Order No.", "Posting Date");
        PurchRcptLine.SetRange("Order No.", PurchHeader."No.");
        if PurchRcptLine.FindFirst() then
            InitialReceiptDate := PurchRcptLine."Posting Date";
        if PurchRcptLine.FindLast() then
            LastReceiptDate := PurchRcptLine."Posting Date";
    end;

    local procedure GetReleasedDateText(PurchHeader: Record "Purchase Header"): Text
    var
        ReleasedDateTime: DateTime;
    begin
        ReleasedDateTime := GetReleasedDateTime(PurchHeader);
        if ReleasedDateTime <> 0DT then
            exit(FormatDateTimeForJson(ReleasedDateTime));

        exit('');
    end;

    local procedure GetReleasedDateOnlyText(PurchHeader: Record "Purchase Header"): Text
    var
        ReleasedDateTime: DateTime;
    begin
        ReleasedDateTime := GetReleasedDateTime(PurchHeader);
        if ReleasedDateTime <> 0DT then
            exit(FormatDateForJson(DT2Date(ReleasedDateTime)));

        exit('');
    end;

    local procedure GetReleasedDateTime(PurchHeader: Record "Purchase Header"): DateTime
    var
        PurchHeaderRef: RecordRef;
        FieldRef: FieldRef;
        ReleasedDateTime: DateTime;
    begin
        PurchHeaderRef.GetTable(PurchHeader);

        if PurchHeaderRef.FieldExist(60211) then begin
            FieldRef := PurchHeaderRef.Field(60211);
            ReleasedDateTime := FieldRef.Value;
            if ReleasedDateTime <> 0DT then
                exit(ReleasedDateTime);
        end;

        exit(0DT);
    end;

    local procedure IsLateReleased(PurchHeader: Record "Purchase Header"): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ReleasedDateTime: DateTime;
        ReleasedTime: Time;
        ReleasingCutOffTime: Time;
    begin
        ReleasedDateTime := GetReleasedDateTime(PurchHeader);
        if ReleasedDateTime = 0DT then
            exit(false);

        if PurchasesPayablesSetup.Get() then
            ReleasingCutOffTime := PurchasesPayablesSetup."APL PO Releasing Cut Off Time";

        if ReleasingCutOffTime = 0T then
            exit(false);

        ReleasedTime := DT2Time(ReleasedDateTime);
        exit((ReleasedTime > ReleasingCutOffTime) and (ReleasedTime <= 235959T));
    end;

    local procedure FormatDateTimeForJson(DateTimeValue: DateTime): Text
    begin
        exit(
          FormatDateForJson(DT2Date(DateTimeValue)) + 'T' +
          Format(DT2Time(DateTimeValue), 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    local procedure GetUserDisplayName(UserSecurityId: Guid): Text
    var
        User: Record User;
    begin
        if IsNullGuid(UserSecurityId) then
            exit('');

        User.SetRange("User Security ID", UserSecurityId);
        if User.FindFirst() then begin
            if User."Full Name" <> '' then
                exit(User."Full Name");

            if User."User Name" <> '' then
                exit(User."User Name");
        end;

        exit(Format(UserSecurityId));
    end;

    local procedure FormatDateForJson(DateValue: Date): Text
    begin
        if DateValue = 0D then
            exit('');

        exit(Format(DateValue, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;
}









