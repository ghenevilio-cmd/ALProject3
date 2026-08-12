codeunit 80219 "TBGC Draft Convert Runner"
{
    // Invoked with Codeunit.Run so the platform rolls the conversion back when it fails.
    // A TryFunction traps the error but keeps everything written before it, which is what
    // left purchase orders behind with no lines, in Open status.
    trigger OnRun()
    var
        ConvertState: Codeunit "TBGC Draft Convert State";
        DraftOrderConverter: Codeunit "TBGC Draft Order Converter";
        CreatedPONo: Code[20];
        WarningMessage: Text;
    begin
        DraftOrderConverter.ConvertDraftOrderToPOWithPostingDate(
          ConvertState.GetDraftOrderNo(),
          ConvertState.GetManualPostingDate(),
          CreatedPONo,
          WarningMessage);

        ConvertState.SetCreatedPONo(CreatedPONo);
        ConvertState.SetWarningMessage(WarningMessage);
    end;
}
