tableextension 80214 "TBGC Pstd Retail Rcvg Hdr" extends "LSC Posted P/R Counting Header"
{
    fields
    {
        field(80257; "TBGC Order Date"; Date)
        {
            Caption = 'Order Date';
            DataClassification = CustomerContent;
        }
        field(80256; "TBGC Original Created By"; Code[50])
        {
            Caption = 'Original CREATED BY';
            DataClassification = CustomerContent;
        }
    }
}
