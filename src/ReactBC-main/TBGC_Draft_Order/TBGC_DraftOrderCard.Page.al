page 80209 "TBGC Draft Order Card"
{
    PageType = Document;
    ApplicationArea = All;
    SourceTable = "TBGC Draft Order Header";
    Caption = 'Draft Order';
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
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
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = All;
                    Editable = CanEditDraft;
                }
                field("Released Date"; Rec."Released Date")
                {
                    ApplicationArea = All;
                    Editable = CanEditDraft;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Created By User ID"; Rec."Created By User ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Last Error Message"; Rec."Last Error Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                }
            }
            part(Lines; "TBGC Draft Order Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
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
                    DraftOrderConverter: Codeunit "TBGC Draft Order Converter";
                    CreatedPONo: Code[20];
                    ManualPostingDate: Date;
                    WarningMessage: Text;
                begin
                    if not GetManualPostingDateFromUser(ManualPostingDate) then
                        exit;

                    ClearLastError();
                    if TryConvertDraftOrder(Rec."No.", ManualPostingDate, CreatedPONo, WarningMessage) then begin
                        CurrPage.Close();
                        if WarningMessage <> '' then begin
                            Message(WarningMessage);
                        end else begin
                            Message('Purchase Order %1 has been created successfully and released.', CreatedPONo);
                        end;
                    end else begin
                        DraftOrderConverter.SetDraftConversionError(Rec."No.", GetLastErrorText());
                        CurrPage.Update(false);
                        Message(GetLastErrorText());
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CanEditDraft := DraftCanEdit();
    end;

    var
        CanEditDraft: Boolean;

    local procedure DraftCanEdit(): Boolean
    var
        DraftOrderMgt: Codeunit "TBGC Draft Order Mgt";
    begin
        exit(DraftOrderMgt.CanEditDraftOrder(Rec."No."));
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

    local procedure GetManualPostingDateFromUser(var ManualPostingDate: Date): Boolean
    var
        ManualPostingDateDialog: Page "TBGC Manual Posting Date";
    begin
        Clear(ManualPostingDate);

        if Rec."Released Date" >= Today then
            exit(true);

        if not Confirm('Do you want to use a previous Posting Date and Document Date for this manual conversion?', false) then
            exit(true);

        if ManualPostingDateDialog.RunModal() = Action::OK then
            ManualPostingDate := ManualPostingDateDialog.GetPostingDate()
        else
            exit(false);

        exit(true);
    end;
}
