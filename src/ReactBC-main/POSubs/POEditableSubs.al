codeunit 80217 "TBGC APL PO Editable Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TBGC_POAccessHelper", 'OnCheckMarketListReceivingPO', '', false, false)]
    local procedure SetMarketListReceivingEditable(PurchaseOrderNo: Code[20]; var IsMarketListReceiving: Boolean)
    var
        MarketListReceivingContext: Codeunit "TBGC ML Receiving Context";
    begin
        if MarketListReceivingContext.IsMarketListReceivingPurchaseOrder(PurchaseOrderNo) then
            IsMarketListReceiving := true;
    end;
}