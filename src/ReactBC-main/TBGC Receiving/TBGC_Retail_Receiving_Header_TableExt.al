tableextension 80212 "TBGC Retail Rcvg Header Ext" extends "LSC P/R Counting Header"
{
    fields
    {
        field(80204; "TBGC Original Created By"; Code[50])
        {
            Caption = 'Original CREATED BY';
            DataClassification = CustomerContent;
        }
        field(80203; "TBGC Order Date"; Date)
        {
            Caption = 'Order Date';
            FieldClass = FlowField;
            CalcFormula = lookup("Purchase Header"."Order Date"
                where(
                    "Document Type" = const(Order),
                    "No." = field("Reference No.")));
            Editable = false;
        }
    }
}
