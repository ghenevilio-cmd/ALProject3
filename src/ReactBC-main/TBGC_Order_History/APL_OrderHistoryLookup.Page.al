page 80299 "TBGC APL Order Hist. Lookup"
{
    PageType = Worksheet;
    ApplicationArea = All;
    SourceTable = "TBGC APL Order History";
    Caption = 'Select Order History';
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;
    SourceTableView = sorting("Location Code", "History Created At", "History ID", "Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Date Filter';

                field(StartDateFilter; StartDateFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Start Date';
                    ToolTip = 'Specifies the first history date to show.';

                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
                field(EndDateFilter; EndDateFilter)
                {
                    ApplicationArea = All;
                    Caption = 'End Date';
                    ToolTip = 'Specifies the last history date to show.';

                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
            }
            repeater(HistoryLines)
            {
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this history line should be loaded.';
                }
                field("History Created At"; Rec."History Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Brand Code"; Rec."Brand Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Brand Description"; Rec."Brand Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ClearSelections();

        if StartDateFilter = 0D then
            StartDateFilter := CalcDate('<-30D>', Today);

        if EndDateFilter = 0D then
            EndDateFilter := Today;

        ApplyFilters();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::LookupOK then
            exit(true);

        if not HasSelectedLines() then
            Error('Select at least one history line.');

        if not Confirm('Are you sure want to load this as current order?') then
            exit(false);

        exit(true);
    end;

    procedure SetLocationFilter(NewLocationFilter: Text)
    begin
        LocationFilter := NewLocationFilter;
    end;

    local procedure ApplyFilters()
    begin
        Rec.Reset();

        if LocationFilter <> '' then
            Rec.SetFilter("Location Code", LocationFilter);

        if (StartDateFilter <> 0D) and (EndDateFilter <> 0D) then
            Rec.SetFilter("History Created At", '%1..%2', CreateDateTime(StartDateFilter, 0T), CreateDateTime(EndDateFilter + 1, 0T) - 1)
        else
            if StartDateFilter <> 0D then
                Rec.SetFilter("History Created At", '>=%1', CreateDateTime(StartDateFilter, 0T))
            else
                if EndDateFilter <> 0D then
                    Rec.SetFilter("History Created At", '<=%1', CreateDateTime(EndDateFilter + 1, 0T) - 1);

        CurrPage.Update(false);
    end;

    local procedure ClearSelections()
    begin
        if LocationFilter <> '' then
            Rec.SetFilter("Location Code", LocationFilter);

        Rec.SetRange(Selected, true);
        if not Rec.IsEmpty() then
            Rec.ModifyAll(Selected, false);

        Rec.Reset();
    end;

    local procedure HasSelectedLines(): Boolean
    var
        OrderHistory: Record "TBGC APL Order History";
    begin
        if LocationFilter <> '' then
            OrderHistory.SetFilter("Location Code", LocationFilter);

        OrderHistory.SetRange(Selected, true);
        exit(not OrderHistory.IsEmpty());
    end;

    var
        StartDateFilter: Date;
        EndDateFilter: Date;
        LocationFilter: Text;
}
