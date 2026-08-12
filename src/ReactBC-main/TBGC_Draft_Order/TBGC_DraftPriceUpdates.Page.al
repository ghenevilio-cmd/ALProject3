page 80221 "TBGC Draft Price Updates"
{
    PageType = List;
    SourceTable = "TBGC Draft Price Update Buf";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'Draft Price Updates';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Updates)
            {
                field("Draft Order No."; Rec."Draft Order No.")
                {
                    ApplicationArea = All;
                }
                field("Draft Line No."; Rec."Draft Line No.")
                {
                    ApplicationArea = All;
                }
                field("Released Date"; Rec."Released Date")
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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
                field("TBGC Brand Code"; Rec."TBGC Brand Code")
                {
                    ApplicationArea = All;
                }
                field("TBGC Zoning Code"; Rec."TBGC Zoning Code")
                {
                    ApplicationArea = All;
                }
                field("TBGC Concept Code"; Rec."TBGC Concept Code")
                {
                    ApplicationArea = All;
                }
                field("TBGC City"; Rec."TBGC City")
                {
                    ApplicationArea = All;
                }
                field("Current Draft Price"; Rec."Current Draft Price")
                {
                    ApplicationArea = All;
                }
                field("Latest APL Price"; Rec."Latest APL Price")
                {
                    ApplicationArea = All;
                }
                field(Difference; Rec.Difference)
                {
                    ApplicationArea = All;
                }
                field("APL Starting Date"; Rec."APL Starting Date")
                {
                    ApplicationArea = All;
                }
                field("APL Entry No."; Rec."APL Entry No.")
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
            action(UpdateSelected)
            {
                ApplicationArea = All;
                Caption = 'Update Selected';
                Image = UpdateDescription;

                trigger OnAction()
                var
                    PriceUpdateMgt: Codeunit "TBGC Draft Price Update Mgt";
                    UpdatedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    UpdatedCount := PriceUpdateMgt.ApplyUpdates(Rec);
                    LoadPreview();
                    Message('%1 line(s) updated in open draft orders from Approved Product List.', UpdatedCount);
                end;
            }
            action(UpdateAll)
            {
                ApplicationArea = All;
                Caption = 'Update All';
                Image = UpdateUnitCost;

                trigger OnAction()
                var
                    PriceUpdateMgt: Codeunit "TBGC Draft Price Update Mgt";
                    UpdatedCount: Integer;
                begin
                    Rec.Reset();
                    UpdatedCount := PriceUpdateMgt.ApplyUpdates(Rec);
                    LoadPreview();
                    Message('%1 line(s) updated in open draft orders from Approved Product List.', UpdatedCount);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            LoadPreview();
    end;

    procedure LoadPreview()
    var
        PriceUpdateMgt: Codeunit "TBGC Draft Price Update Mgt";
    begin
        PriceUpdateMgt.BuildPreview(Rec);
    end;
}
