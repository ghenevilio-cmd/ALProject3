pageextension 80220 "TBGC Pstd Purch Rcpts" extends "Posted Purchase Receipts"
{
    layout
    {
        addafter("No.")
        {
            field("TBGC Original Created By"; Rec."TBGC Original Created By")
            {
                ApplicationArea = All;
                Caption = 'Received By';
                Editable = false;
            }
        }
    }
}
