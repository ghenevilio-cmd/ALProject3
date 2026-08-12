codeunit 80297 "TBGC POS Checkout Runner"
{
    trigger OnRun()
    var
        CheckoutState: Codeunit "TBGC POS Checkout State";
    begin
        CheckoutState.SetResultJson(SaveOrderRequest(
          CheckoutState.GetCartJson(),
          CheckoutState.GetCheckoutRequest()));
    end;

    local procedure SaveOrderRequest(CartJson: Text; IsCheckoutRequest: Boolean): Text
    var
        DraftOrderMgt: Codeunit "TBGC Draft Order Mgt";
    begin
        exit(DraftOrderMgt.SaveDraftOrder(CartJson, IsCheckoutRequest));
    end;
}
