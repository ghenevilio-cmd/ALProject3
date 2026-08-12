tableextension 80269 "TBGC Purch Rcpt Line Ext" extends "Purch. Rcpt. Line"
{
    fields
    {
        field(80251; "TBGC Brand Code"; Code[20])
        {
            Caption = 'TBGC Brand Code';
            DataClassification = ToBeClassified;
        }

        field(80298; "TBGC Actual Receipt Date"; Date)
        {
            Caption = 'Actual Receipt Date';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(80299; "TBGC Original Ordered Qty"; Decimal)
        {
            Caption = 'Original Ordered Qty';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }
}


