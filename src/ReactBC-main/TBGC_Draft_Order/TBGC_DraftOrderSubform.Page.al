page 80208 "TBGC Draft Order Subform"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "TBGC Draft Order Line";
    Caption = 'Draft Order Lines';
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
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
                field("TBGC Brand Code"; Rec."TBGC Brand Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("TBGC Brand Description"; Rec."TBGC Brand Description")
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
                    Editable = CanEditQuantity;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CanEditQuantity := DraftCanEdit();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if not DraftCanEdit() then
            Error('Only allowed open draft or checkout orders can delete lines.');

        exit(true);
    end;

    var
        CanEditQuantity: Boolean;

    local procedure DraftCanEdit(): Boolean
    var
        DraftOrderMgt: Codeunit "TBGC Draft Order Mgt";
    begin
        exit(DraftOrderMgt.CanEditDraftOrder(Rec."Document No."));
    end;
}
