codeunit 80295 "TBGC APL Order History Mgt"
{
    procedure SaveOrderHistory(LocationCode: Code[20]; ExpectedReceiptDate: Date; HistoryLinesJson: Text)
    var
        OrderHistory: Record "TBGC APL Order History";
        JLines: JsonArray;
        JLineToken: JsonToken;
        JLine: JsonObject;
        JToken: JsonToken;
        HistoryId: Guid;
        HistoryCreatedAt: DateTime;
        VendorNo: Code[20];
        ItemNo: Code[20];
        Description: Text[100];
        BrandCode: Code[20];
        UOMCode: Code[20];
        Quantity: Decimal;
        DirectUnitCost: Decimal;
        BrandDescription: Text[100];
        UserIdText: Text;
    begin
        if LocationCode = '' then
            exit;

        DeleteExpiredHistory();

        if not JLines.ReadFrom(HistoryLinesJson) then
            exit;

        if JLines.Count() = 0 then
            exit;

        HistoryId := CreateGuid();
        HistoryCreatedAt := CurrentDateTime();
        UserIdText := UserId();

        foreach JLineToken in JLines do begin
            JLine := JLineToken.AsObject();

            Clear(VendorNo);
            Clear(ItemNo);
            Clear(Description);
            Clear(BrandCode);
            Clear(UOMCode);
            Clear(Quantity);
            Clear(DirectUnitCost);
            Clear(BrandDescription);

            if JLine.Get('vendorNo', JToken) then
                VendorNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(VendorNo));

            if JLine.Get('itemNo', JToken) then
                ItemNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(ItemNo))
            else
                if JLine.Get('itemId', JToken) then
                    ItemNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(ItemNo));

            if JLine.Get('description', JToken) then
                Description := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Description));

            if JLine.Get('brandCode', JToken) then
                BrandCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(BrandCode));

            if JLine.Get('uom', JToken) then
                UOMCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(UOMCode));

            if JLine.Get('quantity', JToken) then
                Quantity := JToken.AsValue().AsDecimal();

            if JLine.Get('directUnitCost', JToken) then
                DirectUnitCost := JToken.AsValue().AsDecimal()
            else
                if JLine.Get('price', JToken) then
                    DirectUnitCost := JToken.AsValue().AsDecimal();

            BrandDescription := GetBrandDescription(VendorNo, ItemNo, BrandCode, UOMCode);

            Clear(OrderHistory);
            OrderHistory.Init();
            OrderHistory."History ID" := HistoryId;
            OrderHistory."Location Code" := LocationCode;
            OrderHistory."History Created At" := HistoryCreatedAt;
            OrderHistory."User ID" := CopyStr(UserIdText, 1, MaxStrLen(OrderHistory."User ID"));
            OrderHistory."Vendor No." := VendorNo;
            OrderHistory."Item No." := ItemNo;
            OrderHistory.Description := Description;
            OrderHistory."Brand Code" := BrandCode;
            OrderHistory."Unit of Measure Code" := UOMCode;
            OrderHistory.Quantity := Quantity;
            OrderHistory."Direct Unit Cost" := DirectUnitCost;
            OrderHistory."Expected Receipt Date" := ExpectedReceiptDate;
            OrderHistory."Brand Description" := BrandDescription;
            OrderHistory.Insert();
        end;
    end;

    procedure GetLatestOrderHistoryJson(LocationCode: Code[20]): Text
    begin
        exit(GetOrderHistoryJsonByLocation(LocationCode));
    end;

    procedure GetValidatedLatestOrderHistoryJson(LocationCode: Code[20]): Text
    var
        LatestHistory: Record "TBGC APL Order History";
    begin
        if LocationCode = '' then
            exit('');

        DeleteExpiredHistory();

        LatestHistory.SetCurrentKey("Location Code", "History Created At", "History ID");
        LatestHistory.SetRange("Location Code", LocationCode);
        if not LatestHistory.FindLast() then
            exit('');

        exit(BuildOrderHistoryJson(LatestHistory, true));
    end;

    procedure GetOrderHistoryJsonByHistoryId(HistoryId: Guid): Text
    var
        OrderHistoryHeader: Record "TBGC APL Order History";
    begin
        if IsNullGuid(HistoryId) then
            exit('');

        DeleteExpiredHistory();

        OrderHistoryHeader.SetRange("History ID", HistoryId);
        if not OrderHistoryHeader.FindFirst() then
            exit('');

        exit(BuildOrderHistoryJson(OrderHistoryHeader, true));
    end;

    procedure GetOrderHistoryJsonBySelected(LocationFilter: Text): Text
    begin
        DeleteExpiredHistory();
        exit(BuildSelectedOrderHistoryJson(LocationFilter));
    end;

    procedure ClearSelectedOrderHistory(LocationFilter: Text)
    var
        OrderHistory: Record "TBGC APL Order History";
    begin
        if LocationFilter <> '' then
            OrderHistory.SetFilter("Location Code", LocationFilter);

        OrderHistory.SetRange(Selected, true);
        if not OrderHistory.IsEmpty() then begin
            OrderHistory.ModifyAll(Selected, false);
            Commit();
        end;
    end;

    local procedure GetOrderHistoryJsonByLocation(LocationCode: Code[20]): Text
    var
        LatestHistory: Record "TBGC APL Order History";
        ResultObj: JsonObject;
        JsonText: Text;
    begin
        ResultObj.Add('hasOrderHistory', false);
        ResultObj.Add('locationCode', LocationCode);

        if LocationCode = '' then begin
            ResultObj.WriteTo(JsonText);
            exit(JsonText);
        end;

        DeleteExpiredHistory();

        LatestHistory.SetCurrentKey("Location Code", "History Created At", "History ID");
        LatestHistory.SetRange("Location Code", LocationCode);
        if not LatestHistory.FindLast() then begin
            ResultObj.WriteTo(JsonText);
            exit(JsonText);
        end;

        exit(BuildOrderHistoryJson(LatestHistory, false));
    end;

    local procedure BuildOrderHistoryJson(OrderHistoryHeader: Record "TBGC APL Order History"; ValidateRetrievable: Boolean): Text
    var
        OrderHistory: Record "TBGC APL Order History";
        HistoryLines: JsonArray;
        ResultObj: JsonObject;
        LineObj: JsonObject;
        JsonText: Text;
    begin
        OrderHistory.SetCurrentKey("History ID");
        OrderHistory.SetRange("History ID", OrderHistoryHeader."History ID");
        if not OrderHistory.FindSet() then
            exit('');

        repeat
            if ValidateRetrievable then
                EnsureHistoryLineRetrievable(OrderHistory);

            Clear(LineObj);
            LineObj.Add('itemId', OrderHistory."Item No.");
            LineObj.Add('name', OrderHistory.Description);
            LineObj.Add('vendorNo', OrderHistory."Vendor No.");
            LineObj.Add('brandCode', OrderHistory."Brand Code");
            LineObj.Add('brandDescription', OrderHistory."Brand Description");
            LineObj.Add('uom', OrderHistory."Unit of Measure Code");
            LineObj.Add('price', OrderHistory."Direct Unit Cost");
            LineObj.Add('quantity', OrderHistory.Quantity);
            LineObj.Add('minimumQuantity', GetMinimumQuantity(OrderHistory));
            HistoryLines.Add(LineObj);
        until OrderHistory.Next() = 0;

        ResultObj.Add('hasOrderHistory', true);
        ResultObj.Add('historyId', Format(OrderHistoryHeader."History ID"));
        ResultObj.Add('locationCode', OrderHistoryHeader."Location Code");
        ResultObj.Add('expectedDeliveryDate', Format(OrderHistoryHeader."Expected Receipt Date", 0, 9));
        ResultObj.Add('orderedAt', Format(OrderHistoryHeader."History Created At", 0, 9));
        ResultObj.Add('lines', HistoryLines);
        ResultObj.WriteTo(JsonText);

        exit(JsonText);
    end;

    local procedure BuildSelectedOrderHistoryJson(LocationFilter: Text): Text
    var
        OrderHistory: Record "TBGC APL Order History";
        FirstSelectedHistory: Record "TBGC APL Order History";
        HistoryLines: JsonArray;
        ResultObj: JsonObject;
        LineObj: JsonObject;
        JsonText: Text;
    begin
        OrderHistory.SetRange(Selected, true);
        if LocationFilter <> '' then
            OrderHistory.SetFilter("Location Code", LocationFilter);

        if not OrderHistory.FindSet() then
            exit('');

        FirstSelectedHistory := OrderHistory;

        repeat
            EnsureHistoryLineRetrievable(OrderHistory);

            Clear(LineObj);
            LineObj.Add('itemId', OrderHistory."Item No.");
            LineObj.Add('name', OrderHistory.Description);
            LineObj.Add('vendorNo', OrderHistory."Vendor No.");
            LineObj.Add('brandCode', OrderHistory."Brand Code");
            LineObj.Add('brandDescription', OrderHistory."Brand Description");
            LineObj.Add('uom', OrderHistory."Unit of Measure Code");
            LineObj.Add('price', OrderHistory."Direct Unit Cost");
            LineObj.Add('quantity', OrderHistory.Quantity);
            LineObj.Add('minimumQuantity', GetMinimumQuantity(OrderHistory));
            HistoryLines.Add(LineObj);
        until OrderHistory.Next() = 0;

        ResultObj.Add('hasOrderHistory', true);
        ResultObj.Add('historyId', Format(FirstSelectedHistory."History ID"));
        ResultObj.Add('locationCode', FirstSelectedHistory."Location Code");
        ResultObj.Add('expectedDeliveryDate', Format(FirstSelectedHistory."Expected Receipt Date", 0, 9));
        ResultObj.Add('orderedAt', Format(FirstSelectedHistory."History Created At", 0, 9));
        ResultObj.Add('lines', HistoryLines);
        ResultObj.WriteTo(JsonText);

        exit(JsonText);
    end;

    local procedure EnsureHistoryLineRetrievable(OrderHistoryLine: Record "TBGC APL Order History")
    var
        Store: Record "LSC Store";
        ZoningCode: Code[20];
        ConceptCode: Code[20];
        City: Text[50];
        HistoryItemInactiveErr: Label 'You cannot retrieve history for Item No. %1 / Brand Code %2 because there is no active matching custom purchase price for the current store setup.';
    begin
        if OrderHistoryLine."Location Code" <> '' then begin
            Store.SetRange("Location Code", OrderHistoryLine."Location Code");
            if Store.FindFirst() then begin
                ZoningCode := Store."TBGC Zoning Code";
                ConceptCode := Store."TBGC Concept Code";
                City := UpperCase(Store.City);
            end;
        end;

        if HasMatchingActivePurchPrice(OrderHistoryLine, ZoningCode, ConceptCode, City, false, false) then
            exit;

        if HasMatchingActivePurchPrice(OrderHistoryLine, ZoningCode, ConceptCode, '', false, true) then
            exit;

        if HasMatchingActivePurchPrice(OrderHistoryLine, ZoningCode, '') then
            exit;

        if HasMatchingActivePurchPrice(OrderHistoryLine, '', ConceptCode) then
            exit;

        if HasMatchingActivePurchPrice(OrderHistoryLine, '', '') then
            exit;

        if (OrderHistoryLine."Unit of Measure Code" <> '') and HasMatchingActivePurchPrice(OrderHistoryLine, ZoningCode, ConceptCode, City, true, false) then
            exit;

        if (OrderHistoryLine."Unit of Measure Code" <> '') and HasMatchingActivePurchPrice(OrderHistoryLine, ZoningCode, ConceptCode, '', true, true) then
            exit;

        if (OrderHistoryLine."Unit of Measure Code" <> '') and HasMatchingActivePurchPrice(OrderHistoryLine, ZoningCode, '', true) then
            exit;

        if (OrderHistoryLine."Unit of Measure Code" <> '') and HasMatchingActivePurchPrice(OrderHistoryLine, '', ConceptCode, true) then
            exit;

        if (OrderHistoryLine."Unit of Measure Code" <> '') and HasMatchingActivePurchPrice(OrderHistoryLine, '', '', true) then
            exit;

        Error(HistoryItemInactiveErr, OrderHistoryLine."Item No.", OrderHistoryLine."Brand Code");
    end;

    local procedure HasMatchingActivePurchPrice(OrderHistoryLine: Record "TBGC APL Order History"; ZoningCode: Code[20]; ConceptCode: Code[20]; City: Text[50]; IgnoreUOM: Boolean; UseGenericCity: Boolean): Boolean
    var
        PurchPrice: Record "Approved Product List";
    begin
        PurchPrice.SetRange(Inactive, false);
        PurchPrice.SetRange("Vendor No.", OrderHistoryLine."Vendor No.");
        PurchPrice.SetRange("Item No.", OrderHistoryLine."Item No.");
        PurchPrice.SetRange("TBGC Brand Code", OrderHistoryLine."Brand Code");

        if not IgnoreUOM then
            if OrderHistoryLine."Unit of Measure Code" <> '' then
                PurchPrice.SetRange("Unit of Measure Code", OrderHistoryLine."Unit of Measure Code");

        if ZoningCode <> '' then
            PurchPrice.SetRange("TBGC Zoning Code", ZoningCode)
        else
            PurchPrice.SetRange("TBGC Zoning Code", '');

        if ConceptCode <> '' then
            PurchPrice.SetRange("TBGC Concept Code", ConceptCode)
        else
            PurchPrice.SetRange("TBGC Concept Code", '');

        ApplyCityFilter(PurchPrice, City, UseGenericCity);
        exit(not PurchPrice.IsEmpty());
    end;

    local procedure HasMatchingActivePurchPrice(OrderHistoryLine: Record "TBGC APL Order History"; ZoningCode: Code[20]; ConceptCode: Code[20]; IgnoreUOM: Boolean): Boolean
    var
        PurchPrice: Record "Approved Product List";
    begin
        PurchPrice.SetRange(Inactive, false);
        PurchPrice.SetRange("Vendor No.", OrderHistoryLine."Vendor No.");
        PurchPrice.SetRange("Item No.", OrderHistoryLine."Item No.");
        PurchPrice.SetRange("TBGC Brand Code", OrderHistoryLine."Brand Code");

        if not IgnoreUOM then
            if OrderHistoryLine."Unit of Measure Code" <> '' then
                PurchPrice.SetRange("Unit of Measure Code", OrderHistoryLine."Unit of Measure Code");

        if ZoningCode <> '' then
            PurchPrice.SetRange("TBGC Zoning Code", ZoningCode)
        else
            PurchPrice.SetRange("TBGC Zoning Code", '');

        if ConceptCode <> '' then
            PurchPrice.SetRange("TBGC Concept Code", ConceptCode)
        else
            PurchPrice.SetRange("TBGC Concept Code", '');

        PurchPrice.SetFilter("TBGC City", '%1|%2', 'ALL', '');
        exit(not PurchPrice.IsEmpty());
    end;

    local procedure HasMatchingActivePurchPrice(OrderHistoryLine: Record "TBGC APL Order History"; ZoningCode: Code[20]; ConceptCode: Code[20]): Boolean
    begin
        exit(HasMatchingActivePurchPrice(OrderHistoryLine, ZoningCode, ConceptCode, false));
    end;

    local procedure DeleteExpiredHistory()
    var
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        OrderHistory: Record "TBGC APL Order History";
        CutoffDate: Date;
        CutoffDateTime: DateTime;
    begin
        if not PurchPayablesSetup.Get() then
            exit;

        if PurchPayablesSetup."APL Order History Ret. Days" <= 0 then
            exit;

        CutoffDate := Today - PurchPayablesSetup."APL Order History Ret. Days";
        CutoffDateTime := CreateDateTime(CutoffDate, 0T);

        OrderHistory.SetFilter("History Created At", '<%1', CutoffDateTime);
        if not OrderHistory.IsEmpty() then
            OrderHistory.DeleteAll();
    end;

    local procedure GetBrandDescription(VendorNo: Code[20]; ItemNo: Code[20]; BrandCode: Code[20]; UOMCode: Code[20]): Text[100]
    var
        CustomPurchasePrice: Record "Approved Product List";
        BrandList: Record "TBGC Brand List";
    begin
        if (ItemNo = '') or (BrandCode = '') then
            exit('');

        CustomPurchasePrice.SetRange(Inactive, false);
        CustomPurchasePrice.SetRange("Vendor No.", VendorNo);
        CustomPurchasePrice.SetRange("Item No.", ItemNo);
        CustomPurchasePrice.SetRange("TBGC Brand Code", BrandCode);

        if UOMCode <> '' then begin
            CustomPurchasePrice.SetRange("Unit of Measure Code", UOMCode);
            if CustomPurchasePrice.FindFirst() then
                exit(CustomPurchasePrice."TBGC Brand Description");
            CustomPurchasePrice.SetRange("Unit of Measure Code");
        end;

        if CustomPurchasePrice.FindFirst() then
            exit(CustomPurchasePrice."TBGC Brand Description");

        BrandList.SetRange("Item No.", ItemNo);
        BrandList.SetRange("TBGC Brand Code", BrandCode);
        if BrandList.FindFirst() then
            exit(BrandList."TBGC Brand Description");

        exit('');
    end;

    local procedure GetMinimumQuantity(OrderHistoryLine: Record "TBGC APL Order History"): Decimal
    var
        PurchPrice: Record "Approved Product List";
        Store: Record "LSC Store";
        ZoningCode: Code[20];
        ConceptCode: Code[20];
        City: Text[50];
    begin
        if OrderHistoryLine."Location Code" <> '' then begin
            Store.SetRange("Location Code", OrderHistoryLine."Location Code");
            if Store.FindFirst() then begin
                ZoningCode := Store."TBGC Zoning Code";
                ConceptCode := Store."TBGC Concept Code";
                City := UpperCase(Store.City);
            end;
        end;

        if TryGetMatchingPurchPrice(OrderHistoryLine, ZoningCode, ConceptCode, City, false, false, PurchPrice) then
            exit(PurchPrice."Minimum Quantity");

        if TryGetMatchingPurchPrice(OrderHistoryLine, ZoningCode, ConceptCode, '', false, true, PurchPrice) then
            exit(PurchPrice."Minimum Quantity");

        if TryGetMatchingPurchPrice(OrderHistoryLine, ZoningCode, '', false, PurchPrice) then
            exit(PurchPrice."Minimum Quantity");

        if TryGetMatchingPurchPrice(OrderHistoryLine, '', ConceptCode, false, PurchPrice) then
            exit(PurchPrice."Minimum Quantity");

        if TryGetMatchingPurchPrice(OrderHistoryLine, '', '', false, PurchPrice) then
            exit(PurchPrice."Minimum Quantity");

        if (OrderHistoryLine."Unit of Measure Code" <> '') and TryGetMatchingPurchPrice(OrderHistoryLine, ZoningCode, ConceptCode, City, true, false, PurchPrice) then
            exit(PurchPrice."Minimum Quantity");

        if (OrderHistoryLine."Unit of Measure Code" <> '') and TryGetMatchingPurchPrice(OrderHistoryLine, ZoningCode, ConceptCode, '', true, true, PurchPrice) then
            exit(PurchPrice."Minimum Quantity");

        if (OrderHistoryLine."Unit of Measure Code" <> '') and TryGetMatchingPurchPrice(OrderHistoryLine, ZoningCode, '', true, PurchPrice) then
            exit(PurchPrice."Minimum Quantity");

        if (OrderHistoryLine."Unit of Measure Code" <> '') and TryGetMatchingPurchPrice(OrderHistoryLine, '', ConceptCode, true, PurchPrice) then
            exit(PurchPrice."Minimum Quantity");

        if (OrderHistoryLine."Unit of Measure Code" <> '') and TryGetMatchingPurchPrice(OrderHistoryLine, '', '', true, PurchPrice) then
            exit(PurchPrice."Minimum Quantity");

        exit(0);
    end;

    local procedure TryGetMatchingPurchPrice(OrderHistoryLine: Record "TBGC APL Order History"; ZoningCode: Code[20]; ConceptCode: Code[20]; City: Text[50]; IgnoreUOM: Boolean; UseGenericCity: Boolean; var PurchPrice: Record "Approved Product List"): Boolean
    begin
        PurchPrice.Reset();
        PurchPrice.SetRange(Inactive, false);
        PurchPrice.SetRange("Vendor No.", OrderHistoryLine."Vendor No.");
        PurchPrice.SetRange("Item No.", OrderHistoryLine."Item No.");
        PurchPrice.SetRange("TBGC Brand Code", OrderHistoryLine."Brand Code");

        if not IgnoreUOM then
            if OrderHistoryLine."Unit of Measure Code" <> '' then
                PurchPrice.SetRange("Unit of Measure Code", OrderHistoryLine."Unit of Measure Code");

        if ZoningCode <> '' then
            PurchPrice.SetRange("TBGC Zoning Code", ZoningCode)
        else
            PurchPrice.SetRange("TBGC Zoning Code", '');

        if ConceptCode <> '' then
            PurchPrice.SetRange("TBGC Concept Code", ConceptCode)
        else
            PurchPrice.SetRange("TBGC Concept Code", '');

        ApplyCityFilter(PurchPrice, City, UseGenericCity);
        exit(PurchPrice.FindFirst());
    end;

    local procedure TryGetMatchingPurchPrice(OrderHistoryLine: Record "TBGC APL Order History"; ZoningCode: Code[20]; ConceptCode: Code[20]; IgnoreUOM: Boolean; var PurchPrice: Record "Approved Product List"): Boolean
    begin
        PurchPrice.Reset();
        PurchPrice.SetRange(Inactive, false);
        PurchPrice.SetRange("Vendor No.", OrderHistoryLine."Vendor No.");
        PurchPrice.SetRange("Item No.", OrderHistoryLine."Item No.");
        PurchPrice.SetRange("TBGC Brand Code", OrderHistoryLine."Brand Code");

        if not IgnoreUOM then
            if OrderHistoryLine."Unit of Measure Code" <> '' then
                PurchPrice.SetRange("Unit of Measure Code", OrderHistoryLine."Unit of Measure Code");

        if ZoningCode <> '' then
            PurchPrice.SetRange("TBGC Zoning Code", ZoningCode)
        else
            PurchPrice.SetRange("TBGC Zoning Code", '');

        if ConceptCode <> '' then
            PurchPrice.SetRange("TBGC Concept Code", ConceptCode)
        else
            PurchPrice.SetRange("TBGC Concept Code", '');

        PurchPrice.SetFilter("TBGC City", '%1|%2', 'ALL', '');
        exit(PurchPrice.FindFirst());
    end;

    local procedure ApplyCityFilter(var PurchPrice: Record "Approved Product List"; City: Text[50]; UseGenericCity: Boolean)
    begin
        if UseGenericCity then
            PurchPrice.SetFilter("TBGC City", '%1|%2', 'ALL', '')
        else
            PurchPrice.SetRange("TBGC City", City);
    end;
}
