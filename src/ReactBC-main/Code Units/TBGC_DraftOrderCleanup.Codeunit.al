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
        // Keep converted drafts long enough for an OMS retry or an operator to trace DRF -> PO.
        DraftOrderHeader.SetFilter("Created At", '<%1', CreateDateTime(CalcDate('<-30D>', Today), 0T));
        while DraftOrderHeader.FindFirst() do
            DraftOrderHeader.Delete(true);
    end;
}
