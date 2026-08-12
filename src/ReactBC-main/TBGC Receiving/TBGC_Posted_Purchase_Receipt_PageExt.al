pageextension 80219 "TBGC Pstd Purch Rcpt Pg" extends "Posted Purchase Receipt"
{
    layout
    {
        addafter("Order No.")
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
