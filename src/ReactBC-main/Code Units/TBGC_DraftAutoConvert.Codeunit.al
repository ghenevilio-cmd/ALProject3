codeunit 80213 "TBGC Draft Auto Convert"
{
    trigger OnRun()
    begin
        AutoConvertReleasedDraftOrders();
    end;

    procedure AutoConvertReleasedDraftOrders()
    var
        DraftOrderConverter: Codeunit "TBGC Draft Order Converter";
        DraftOrderHeader: Record "TBGC Draft Order Header";
        CreatedPONo: Code[20];
        WarningMessage: Text;
        ConvertedCount: Integer;
        FailedCount: Integer;
        FailureSummary: Text;
        SuccessSummary: Text;
    begin
        DraftOrderHeader.SetRange(Status, DraftOrderHeader.Status::Open);
        DraftOrderHeader.SetRange("Auto Convert In Progress", false);

        if not DraftOrderHeader.FindSet() then
            exit;

        repeat
            if DraftOrderHeader."Released Date" <> Today then
                continue;

            Clear(CreatedPONo);
            Clear(WarningMessage);
            ClearLastError();
            if not TryClaimDraftOrder(DraftOrderHeader."No.") then begin
                FailedCount += 1;

                if FailureSummary <> '' then
                    FailureSummary += '\';

                FailureSummary +=
                  StrSubstNo(
                    'Draft %1 skipped: %2',
                    DraftOrderHeader."No.",
                    CopyStr(GetLastErrorText(), 1, 180));
            end else
                if not TryValidateDraftOrder(DraftOrderHeader."No.") then begin
                    DraftOrderConverter.ReleaseDraftAutoConvertClaim(DraftOrderHeader."No.");
                    DraftOrderConverter.SetDraftConversionError(DraftOrderHeader."No.", GetLastErrorText());
                    FailedCount += 1;

                    if FailureSummary <> '' then
                        FailureSummary += '\';

                    FailureSummary +=
                      StrSubstNo(
                        'Draft %1 failed: %2',
                        DraftOrderHeader."No.",
                        CopyStr(GetLastErrorText(), 1, 180));
                end else
                    if not TryConvertDraftOrder(DraftOrderHeader."No.", CreatedPONo, WarningMessage) then begin
                        DraftOrderConverter.ReleaseDraftAutoConvertClaim(DraftOrderHeader."No.");
                        DraftOrderConverter.SetDraftConversionError(DraftOrderHeader."No.", GetLastErrorText());
                        FailedCount += 1;

                        if FailureSummary <> '' then
                            FailureSummary += '\';

                        FailureSummary +=
                          StrSubstNo(
                            'Draft %1 failed: %2',
                            DraftOrderHeader."No.",
                            CopyStr(GetLastErrorText(), 1, 180));
                    end else begin
                        ConvertedCount += 1;
                        if SuccessSummary <> '' then
                            SuccessSummary += '\';

                        SuccessSummary +=
                          StrSubstNo(
                            'Draft %1 converted to PO %2',
                            DraftOrderHeader."No.",
                            CreatedPONo);
                        Commit();
                    end;
        until DraftOrderHeader.Next() = 0;

        Commit();
        if FailedCount > 0 then
            Message(
              'Auto-convert finished with %1 converted and %2 failed.\%3',
              ConvertedCount,
              FailedCount,
              FailureSummary)
        else
            if ConvertedCount > 0 then
                Message(
                  'Auto-convert finished. %1 draft order(s) successfully converted.\%2',
                  ConvertedCount,
                  SuccessSummary)
            else
                Message('Auto-convert ran but no draft orders were scheduled for today (%1).', Today);
    end;

    [TryFunction]
    local procedure TryValidateDraftOrder(DraftOrderNo: Code[20])
    var
        DraftOrderConverter: Codeunit "TBGC Draft Order Converter";
    begin
        DraftOrderConverter.ValidateDraftOrderForPOCreation(DraftOrderNo, false);
    end;

    [TryFunction]
    local procedure TryConvertDraftOrder(DraftOrderNo: Code[20]; var CreatedPONo: Code[20]; var WarningMessage: Text)
    var
        DraftOrderConverter: Codeunit "TBGC Draft Order Converter";
    begin
        DraftOrderConverter.ConvertDraftOrderToPOJobQueue(DraftOrderNo, CreatedPONo, WarningMessage);
    end;

    [TryFunction]
    local procedure TryClaimDraftOrder(DraftOrderNo: Code[20])
    var
        DraftOrderConverter: Codeunit "TBGC Draft Order Converter";
    begin
        DraftOrderConverter.ClaimDraftOrderForAutoConvert(DraftOrderNo);
    end;
}
