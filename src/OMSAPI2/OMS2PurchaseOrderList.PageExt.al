pageextension 80227 "OMS2 Purchase Order List" extends "Purchase Order List"
{
    layout
    {
        addafter("No.")
        {
            field("OMS PO Ref. No."; Rec."OMS PO Ref. No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Shows the OMS order reference linked to this purchase order.';
            }
        }
    }
}
