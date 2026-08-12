pageextension 80217 "TBGC Pstd Retail Rcvg Pg" extends "LSC Retail Posted Receiving"
{
    layout
    {
        addafter("Reference Name")
        {
            field("TBGC Order Date"; Rec."TBGC Order Date")
            {
                ApplicationArea = All;
                Caption = 'Order Date';
                Editable = false;
            }
            field("TBGC Original Created By"; Rec."TBGC Original Created By")
            {
                ApplicationArea = All;
                Caption = 'Original CREATED BY';
                Editable = false;
            }
        }
    }
}
