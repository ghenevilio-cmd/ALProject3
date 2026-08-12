pageextension 80273 "TBGC Posted Purch Rcpt Subf" extends "Posted Purchase Rcpt. Subform"
{
    layout
    {
        addbefore(Description)
        {
            field("TBGC Brand Code"; Rec."TBGC Brand Code")
            {
                ApplicationArea = All;
            }
            field("TBGC Actual Receipt Date"; Rec."TBGC Actual Receipt Date")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the actual receipt date entered on the purchase order line when the receipt was posted.';
            }
        }

        addafter(Quantity)
        {
            field("TBGC Original Ordered Qty"; Rec."TBGC Original Ordered Qty")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the original ordered quantity before standard over-receipt handling increased the line quantity.';
            }
        }
    }
}

