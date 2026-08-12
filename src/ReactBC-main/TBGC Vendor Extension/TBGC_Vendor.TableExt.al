tableextension 80250 "TBGC Vendor Ext" extends Vendor
{
    fields
    {
        field(80290; "TBGC Minimum Order Amount"; Decimal)
        {
            Caption = 'Minimum Amount Order';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
    }
}
