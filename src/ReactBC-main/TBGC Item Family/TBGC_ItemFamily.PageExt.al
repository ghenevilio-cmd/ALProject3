pageextension 80300 "TBGC Item Family Ext" extends "LSC Item Families"
{
    layout
    {
        addafter(Description)
        {
            field("TBGC PO Rcvg Threshold %"; Rec."TBGC PO Rcvg Threshold %")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the percentage above the ordered quantity that can be received for items in this item family.';
            }
            field("TBGC Delivery Lead Time (Days)"; Rec."TBGC Delivery Lead Time (Days)")
            {
                ApplicationArea = All;
                ObsoleteState = Pending;
                ObsoleteReason = 'Not used anymore.';
                Visible = false;
                ObsoleteTag = '1.0.0.4';
            }
        }
    }
}
