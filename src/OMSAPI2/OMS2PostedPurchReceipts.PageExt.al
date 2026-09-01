pageextension 80229 "OMS2 Posted Purch Receipts" extends "Posted Purchase Receipts"
{
    layout
    {
        addafter("No.")
        {
            field("OMS PO Ref. No."; Rec."OMS PO Ref. No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Shows the OMS order reference linked to this receipt.';
            }
            field("OMS Receiving Ref. No."; Rec."OMS Receiving Ref. No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Shows the OMS receiving reference linked to this receipt.';
            }
        }
    }
}
