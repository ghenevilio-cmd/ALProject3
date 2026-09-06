codeunit 80213 "TBGC Draft Auto Convert"
{
    trigger OnRun()
    begin
        AutoConvertReleasedDraftOrders();
    end;

    procedure AutoConvertReleasedDraftOrders()
    var
        ConvertState: Codeunit "TBGC Draft Convert State";
        DraftOrderConverter: Codeunit "TBGC Draft Order Converter";
        DraftOrderHeader: Record "TBGC Draft Order Header";
        CreatedPONo: Code[20];
        WarningMessage: Text;
        ConvertedCount: Integer;
        FailedCount: Integer;
        ErrorText: Text;
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

            ConvertState.ClearState();
            ConvertState.SetDraftOrderNo(DraftOrderHeader."No.");
            ConvertState.SetJobQueueMode(true);
            ClearLastError();
            if not Codeunit.Run(Codeunit::"TBGC Draft Convert Runner") then begin
                ErrorText := GetLastErrorText();
                DraftOrderConverter.SetDraftConversionError(DraftOrderHeader."No.", ErrorText);
                FailedCount += 1;
                if FailureSummary <> '' then
                    FailureSummary += '\';
                FailureSummary += StrSubstNo('Draft %1 failed: %2', DraftOrderHeader."No.",
                    CopyStr(ErrorText, 1, 180));
            end else begin
                CreatedPONo := ConvertState.GetCreatedPONo();
                WarningMessage := ConvertState.GetWarningMessage();
                ConvertedCount += 1;
                if SuccessSummary <> '' then
                    SuccessSummary += '\';
                SuccessSummary += StrSubstNo('Draft %1 converted to PO %2', DraftOrderHeader."No.", CreatedPONo);
            end;
        until DraftOrderHeader.Next() = 0;
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

}
