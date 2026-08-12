codeunit 80285 "TBGC ML Receiving Context"
{
    SingleInstance = true;

    procedure SetPurchaseOrderNo(PurchaseOrderNo: Code[20]; ReadOnly: Boolean)
    begin
        CurrentPurchaseOrderNo := PurchaseOrderNo;
        CurrentPurchaseOrderReadOnly := ReadOnly;
    end;

    procedure ClearPurchaseOrderNo()
    begin
        Clear(CurrentPurchaseOrderNo);
        Clear(CurrentPurchaseOrderReadOnly);
    end;

    procedure IsMarketListReceivingPurchaseOrder(PurchaseOrderNo: Code[20]): Boolean
    begin
        exit((CurrentPurchaseOrderNo <> '') and (CurrentPurchaseOrderNo = PurchaseOrderNo));
    end;

    procedure IsMarketListReceivingReadOnly(PurchaseOrderNo: Code[20]): Boolean
    begin
        exit(IsMarketListReceivingPurchaseOrder(PurchaseOrderNo) and CurrentPurchaseOrderReadOnly);
    end;

    var
        CurrentPurchaseOrderNo: Code[20];
        CurrentPurchaseOrderReadOnly: Boolean;
}
