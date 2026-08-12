codeunit 80209 "TBGC Released Date Mgt"
{
    procedure GetReleasedDateFromUser(): Date
    var
        ReleasedDateDialog: Page "TBGC Released Date Dialog";
    begin
        if ReleasedDateDialog.RunModal() = Action::OK then
            exit(ReleasedDateDialog.GetReleasedDate())
        else
            exit(0D);
    end;

    procedure GetReleasedDateFromUserWithNeedByDate(NeedByDate: Date): Date
    var
        ReleasedDateDialog: Page "TBGC Released Date Dialog";
    begin
        ReleasedDateDialog.SetNeedByDate(NeedByDate);
        if ReleasedDateDialog.RunModal() = Action::OK then
            exit(ReleasedDateDialog.GetReleasedDate())
        else
            exit(0D);
    end;

    procedure ValidateReleasedDate(SelectedDate: Date): Boolean
    var
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        MaxAllowedDate: Date;
    begin
        if SelectedDate < Today then
            Error('Released Date cannot be earlier than today.');

        if not PurchPayablesSetup.Get() then
            exit(true);

        if PurchPayablesSetup."APL Draft Rel. Date Max Days" <= 0 then
            exit(true);

        MaxAllowedDate := Today + PurchPayablesSetup."APL Draft Rel. Date Max Days";
        if SelectedDate > MaxAllowedDate then
            Error(
              'Released Date cannot be later than %1. Purchase & Payables Setup allows up to %2 day(s) from today for draft orders.',
              MaxAllowedDate,
              PurchPayablesSetup."APL Draft Rel. Date Max Days");

        exit(true);
    end;
}
