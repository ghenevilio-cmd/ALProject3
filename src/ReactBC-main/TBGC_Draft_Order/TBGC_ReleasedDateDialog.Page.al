page 80211 "TBGC Released Date Dialog"
{
    PageType = StandardDialog;
    SourceTable = "TBGC Draft Order Header";
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Assign Released Date';

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                field(ReleasedDateLabel; 'Assign a Released Date:')
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
                field(ReleasedDate; TempReleasedDate)
                {
                    Caption = 'Released Date';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ValidateReleasedDate(TempReleasedDate);
                    end;
                }
            }
        }
    }

    var
        ReleasedDateMgt: Codeunit "TBGC Released Date Mgt";
        TempReleasedDate: Date;
        NeedByDate: Date;

    trigger OnOpenPage()
    begin
        TempReleasedDate := Today;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            ValidateReleasedDate(TempReleasedDate);
    end;

    procedure SetNeedByDate(NewNeedByDate: Date)
    begin
        NeedByDate := NewNeedByDate;
    end;

    procedure GetReleasedDate(): Date
    begin
        exit(TempReleasedDate);
    end;

    local procedure ValidateReleasedDate(SelectedDate: Date)
    begin
        ReleasedDateMgt.ValidateReleasedDate(SelectedDate);

        if (NeedByDate <> 0D) and (SelectedDate > NeedByDate) then
            Error('Need by Date cannot be earlier than Released Date. Need by Date is %1.', NeedByDate);
    end;
}
