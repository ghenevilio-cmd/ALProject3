codeunit 80211 "TBGC Draft Order Cleanup"
{
    trigger OnRun()
    begin
        DeleteConvertedDraftOrders();
    end;

    procedure DeleteConvertedDraftOrders()
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
    begin
        DraftOrderHeader.SetRange(Status, DraftOrderHeader.Status::Converted);
        while DraftOrderHeader.FindFirst() do
            DraftOrderHeader.Delete(true);
    end;
}
