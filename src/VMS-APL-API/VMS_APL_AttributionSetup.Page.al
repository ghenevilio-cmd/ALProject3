page 80269 "VMS APL Attribution Setup"
{
    PageType = Card;
    SourceTable = "VMS APL Attribution Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'VMS APL Employee Attribution Setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Enables employee attribution only for the configured integration user in this company.';
                }
                field("Integration User Security ID"; Rec."Integration User Security ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Identifies the approved VMS pricing run-as user by its immutable BC security ID.';
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        if not Rec.Get('') then begin
            Rec.Init();
            Rec.Insert(true);
        end;
    end;
}
