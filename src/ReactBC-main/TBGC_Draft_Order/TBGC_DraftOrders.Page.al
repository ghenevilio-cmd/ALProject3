page 80210 "TBGC Draft Orders"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "TBGC Draft Order Header";
    Caption = 'Draft Orders';
    CardPageId = "TBGC Draft Order Card";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Location Code", Status, "Created At") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Drafts)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = All;
                }
                field("Released Date"; Rec."Released Date")
                {
                    ApplicationArea = All;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }
                field("Created By User ID"; Rec."Created By User ID")
                {
                    ApplicationArea = All;
                }
                field("Last Error Message"; Rec."Last Error Message")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ConvertToPO)
            {
                ApplicationArea = All;
                Caption = 'Convert to Purchase Order';
                Image = CreateDocument;
                Enabled = Rec.Status = Rec.Status::Open;

                trigger OnAction()
                var
                    SelectedDraftOrders: Record "TBGC Draft Order Header";
                    ManualPostingDate: Date;
                    ConvertedCount: Integer;
                    FailedCount: Integer;
                    CreatedPONosText: Text;
                begin
                    CurrPage.SetSelectionFilter(SelectedDraftOrders);
                    if SelectedDraftOrders.IsEmpty() then begin
                        SelectedDraftOrders := Rec;
                        if SelectedDraftOrders."No." = '' then
                            exit;
                    end;

                    if not GetManualPostingDateFromUser(SelectedDraftOrders, ManualPostingDate) then
                        exit;

                    ConvertSelectedDraftOrders(SelectedDraftOrders, ManualPostingDate, ConvertedCount, FailedCount, CreatedPONosText);
                    CurrPage.Update(false);

                    if FailedCount = 0 then begin
                        if CreatedPONosText <> '' then
                            Message('%1 draft order(s) converted successfully. Created PO(s): %2', ConvertedCount, CreatedPONosText)
                        else
                            Message('%1 draft order(s) converted successfully.', ConvertedCount);
                    end else
                        Message(
                          '%1 draft order(s) converted successfully. Created PO(s): %2. %3 draft order(s) failed. Check Last Error Message for details.',
                          ConvertedCount,
                          CreatedPONosText,
                          FailedCount);
                end;
            }
        }
    }

    local procedure ConvertSelectedDraftOrders(var SelectedDraftOrders: Record "TBGC Draft Order Header"; ManualPostingDate: Date; var ConvertedCount: Integer; var FailedCount: Integer; var CreatedPONosText: Text)
    var
        DraftOrderConverter: Codeunit "TBGC Draft Order Converter";
        CreatedPONo: Code[20];
        WarningMessage: Text;
    begin
        ConvertedCount := 0;
        FailedCount := 0;
        Clear(CreatedPONosText);

        if SelectedDraftOrders.FindSet() then
            repeat
                if SelectedDraftOrders.Status <> SelectedDraftOrders.Status::Open then
                    continue;

                ClearLastError();
                Clear(CreatedPONo);
                Clear(WarningMessage);

                if TryConvertDraftOrder(SelectedDraftOrders."No.", ManualPostingDate, CreatedPONo, WarningMessage) then
                    begin
                        ConvertedCount += 1;
                        AppendCreatedPONo(CreatedPONosText, CreatedPONo);
                    end
                else begin
                    DraftOrderConverter.SetDraftConversionError(SelectedDraftOrders."No.", GetLastErrorText());
                    FailedCount += 1;
                end;
            until SelectedDraftOrders.Next() = 0;
    end;

    local procedure TryConvertDraftOrder(DraftOrderNo: Code[20]; ManualPostingDate: Date; var CreatedPONo: Code[20]; var WarningMessage: Text): Boolean
    var
        ConvertState: Codeunit "TBGC Draft Convert State";
    begin
        ConvertState.ClearState();
        ConvertState.SetDraftOrderNo(DraftOrderNo);
        ConvertState.SetManualPostingDate(ManualPostingDate);

        if not Codeunit.Run(Codeunit::"TBGC Draft Convert Runner") then
            exit(false);

        CreatedPONo := ConvertState.GetCreatedPONo();
        WarningMessage := ConvertState.GetWarningMessage();
        exit(true);
    end;

    local procedure GetManualPostingDateFromUser(var SelectedDraftOrders: Record "TBGC Draft Order Header"; var ManualPostingDate: Date): Boolean
    var
        ManualPostingDateDialog: Page "TBGC Manual Posting Date";
    begin
        Clear(ManualPostingDate);

        if not HasSelectedDraftOrderReleasedBeforeToday(SelectedDraftOrders) then
            exit(true);

        if not Confirm('Do you want to use a previous Posting Date and Document Date for this manual conversion?', false) then
            exit(true);

        if ManualPostingDateDialog.RunModal() = Action::OK then
            ManualPostingDate := ManualPostingDateDialog.GetPostingDate()
        else
            exit(false);

        exit(true);
    end;

    local procedure HasSelectedDraftOrderReleasedBeforeToday(var SelectedDraftOrders: Record "TBGC Draft Order Header"): Boolean
    begin
        if SelectedDraftOrders.FindSet() then
            repeat
                if (SelectedDraftOrders.Status = SelectedDraftOrders.Status::Open) and
                   (SelectedDraftOrders."Released Date" < Today)
                then
                    exit(true);
            until SelectedDraftOrders.Next() = 0;

        exit(false);
    end;

    local procedure AppendCreatedPONo(var CreatedPONosText: Text; CreatedPONo: Code[20])
    begin
        if CreatedPONo = '' then
            exit;

        if CreatedPONosText = '' then
            CreatedPONosText := CreatedPONo
        else
            CreatedPONosText += ', ' + CreatedPONo;
    end;
}
