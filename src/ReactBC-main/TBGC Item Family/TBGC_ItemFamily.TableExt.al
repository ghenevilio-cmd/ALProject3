tableextension 80300 "TBGC Item Family Ext" extends "LSC Item Family"
{
    fields
    {
        field(80297; "TBGC PO Rcvg Threshold %"; Decimal)
        {
            Caption = 'PO Receiving Threshold %';
            DataClassification = CustomerContent;
            MinValue = 0;
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
        }

        field(80300; "TBGC Delivery Lead Time (Days)"; Integer)
        {
            Caption = 'Delivery Lead Time (Days)';
            DataClassification = ToBeClassified;
            ObsoleteState = Pending;
            ObsoleteReason = 'Not used anymore';
            ObsoleteTag = '1.0.0.4';
        }
    }
}
