page 80214 "TBGC Manual Posting Date"
{
    PageType = StandardDialog;
    Caption = 'Select Posting Date';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                field(PostingDateLabel; 'Select a previous Posting Date. Document Date will use the same value:')
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
                field(PostingDate; TempPostingDate)
                {
                    Caption = 'Posting Date';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ValidatePostingDate(TempPostingDate);
                    end;
                }
            }
        }
    }

    var
        TempPostingDate: Date;

    trigger OnOpenPage()
    begin
        TempPostingDate := CalcDate('<-1D>', Today);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            ValidatePostingDate(TempPostingDate);
    end;

    procedure GetPostingDate(): Date
    begin
        exit(TempPostingDate);
    end;

    local procedure ValidatePostingDate(SelectedDate: Date)
    begin
        if SelectedDate = 0D then
            Error('Posting Date is required.');

        if SelectedDate >= Today then
            Error('Posting Date must be earlier than today for previous-day manual conversion.');
    end;
}
