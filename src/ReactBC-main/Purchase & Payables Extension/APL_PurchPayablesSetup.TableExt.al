tableextension 80296 "APL Purch Payables Setup Ext" extends "Purchases & Payables Setup"
{
    fields
    {
        field(80294; "APL Order History Ret. Days"; Integer)
        {
            Caption = 'APL Order History Retention Days';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(80295; "APL Draft Rel. Date Max Days"; Integer)
        {
            Caption = 'APL Draft Released Date Max Days';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(80296; "APL PO Releasing Cut Off Time"; Time)
        {
            Caption = 'PO Releasing Cut Off Time';
            DataClassification = CustomerContent;
        }
        field(80299; "APL Show Partial Receiving"; Boolean)
        {
            Caption = 'Show Partial Receiving';
            DataClassification = CustomerContent;
            InitValue = true;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by Partial Receiving Visibility Days.';
            ObsoleteTag = '1.0.1.25';
        }
        field(80293; "APL Partial Rcvg View Days"; Integer)
        {
            Caption = 'Partial Receiving Visibility Days';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(80300; "APL Require End Date Price Chg"; Boolean)
        {
            Caption = 'Require Ending Date for APL Price Change';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }
}
