pageextension 80228 "OMS2 Purchase Order" extends "Purchase Order"
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
