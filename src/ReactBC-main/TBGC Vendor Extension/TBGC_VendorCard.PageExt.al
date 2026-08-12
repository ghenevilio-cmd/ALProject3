pageextension 80251 "TBGC Vendor Card Ext" extends "Vendor Card"
{
    layout
    {
        addafter("Application Method")
        {
            field("TBGC Minimum Order Amount"; Rec."TBGC Minimum Order Amount")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the minimum order amount required for this vendor in Market List.';
            }
        }
    }
}
