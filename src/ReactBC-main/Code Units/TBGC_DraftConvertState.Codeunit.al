codeunit 80218 "TBGC Draft Convert State"
{
    SingleInstance = true;

    var
        DraftOrderNo: Code[20];
        ManualPostingDate: Date;
        CreatedPONo: Code[20];
        WarningMessage: Text;

    procedure SetDraftOrderNo(NewDraftOrderNo: Code[20])
    begin
        DraftOrderNo := NewDraftOrderNo;
    end;

    procedure GetDraftOrderNo(): Code[20]
    begin
        exit(DraftOrderNo);
    end;

    procedure SetManualPostingDate(NewManualPostingDate: Date)
    begin
        ManualPostingDate := NewManualPostingDate;
    end;

    procedure GetManualPostingDate(): Date
    begin
        exit(ManualPostingDate);
    end;

    procedure SetCreatedPONo(NewCreatedPONo: Code[20])
    begin
        CreatedPONo := NewCreatedPONo;
    end;

    procedure GetCreatedPONo(): Code[20]
    begin
        exit(CreatedPONo);
    end;

    procedure SetWarningMessage(NewWarningMessage: Text)
    begin
        WarningMessage := NewWarningMessage;
    end;

    procedure GetWarningMessage(): Text
    begin
        exit(WarningMessage);
    end;

    procedure ClearState()
    begin
        Clear(DraftOrderNo);
        Clear(ManualPostingDate);
        Clear(CreatedPONo);
        Clear(WarningMessage);
    end;
}
