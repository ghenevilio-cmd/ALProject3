page 80282 "Market List Receiving"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Market List Receiving';

    layout
    {
        area(Content)
        {
            usercontrol(ReceivingUI; "TBGC Receiving Control Addin")
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                begin
                    RefreshReceivingWorkspace();
                end;

                trigger OpenPurchaseOrder(DocumentNo: Text; LocationCode: Text)
                var
                    PurchHeader: Record "Purchase Header";
                begin
                    if DocumentNo = '' then
                        exit;

                    if LocationCode <> '' then
                        SelectedLocationCode := CopyStr(LocationCode, 1, MaxStrLen(SelectedLocationCode));

                    PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
                    PurchHeader.SetRange("No.", CopyStr(DocumentNo, 1, MaxStrLen(PurchHeader."No.")));
                    if not PurchHeader.FindFirst() then begin
                        RefreshReceivingWorkspace();
                        exit;
                    end;

                    OpenReceivingDocumentAndRefresh(PurchHeader);
                end;

                trigger PrintPurchaseOrder(DocumentNo: Text)
                var
                    PurchHeader: Record "Purchase Header";
                    ReceivingMgt: Codeunit "TBGC Receiving Mgt";
                begin
                    if DocumentNo = '' then
                        exit;

                    PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
                    PurchHeader.SetRange("No.", CopyStr(DocumentNo, 1, MaxStrLen(PurchHeader."No.")));
                    if not PurchHeader.FindFirst() then
                        exit;

                    ReceivingMgt.PrintPurchaseOrder(PurchHeader);
                end;

                trigger LocationFilterChanged(LocationCode: Text)
                begin
                    SelectedLocationCode := CopyStr(LocationCode, 1, MaxStrLen(SelectedLocationCode));
                    RefreshReceivingWorkspace();
                end;

                trigger LoadReceivingOrdersPage(LocationCode: Text; Skip: Integer; Take: Integer; SearchText: Text; StatusFilter: Text; ReleasedDateFrom: Text; ReleasedDateTo: Text)
                var
                    ReceivingMgt: Codeunit "TBGC Receiving Mgt";
                begin
                    if LocationCode <> '' then
                        SelectedLocationCode := CopyStr(LocationCode, 1, MaxStrLen(SelectedLocationCode));

                    CurrPage.ReceivingUI.loadReceivingOrders(
                      ReceivingMgt.GetReceivingOrdersPageJson(
                        SelectedLocationCode,
                        Skip,
                        Take,
                        SearchText,
                        StatusFilter,
                        ReleasedDateFrom,
                        ReleasedDateTo,
                        Skip = 0));
                end;
            }
        }
    }

    var
        SelectedLocationCode: Code[20];

    local procedure OpenReceivingDocumentAndRefresh(var PurchHeader: Record "Purchase Header")
    var
        ReceivingMgt: Codeunit "TBGC Receiving Mgt";
    begin
        ReceivingMgt.OpenReceivingDocument(PurchHeader, SelectedLocationCode);
        RefreshReceivingWorkspace();
        CurrPage.Update(false);
    end;

    local procedure RefreshReceivingWorkspace()
    var
        ReceivingMgt: Codeunit "TBGC Receiving Mgt";
    begin
        CurrPage.ReceivingUI.init(ReceivingMgt.GetReceivingContextJson(SelectedLocationCode));
    end;
}



