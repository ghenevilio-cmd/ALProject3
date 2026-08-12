tableextension 80215 "TBGC Purch Rcpt Header Ext" extends "Purch. Rcpt. Header"
{
    fields
    {
        field(80256; "TBGC Original Created By"; Code[50])
        {
            Caption = 'Received By';
            DataClassification = CustomerContent;
        }
    }
}
