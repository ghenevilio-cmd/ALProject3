pageextension 80253 "OMS2 Draft Order List" extends "TBGC Draft Orders"
{
    layout
    {
        addafter("No.")
        {
            field("OMS PO Ref. No."; Rec."OMS PO Ref. No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Shows the OMS order reference that created this Draft Order.';
            }
        }
    }
}

pageextension 80254 "OMS2 Draft Order Card" extends "TBGC Draft Order Card"
{
    layout
    {
        addafter("No.")
        {
            field("OMS PO Ref. No."; Rec."OMS PO Ref. No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Shows the OMS order reference that created this Draft Order.';
            }
        }
    }
}
