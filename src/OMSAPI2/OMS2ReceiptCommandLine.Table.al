/*
 * The v1 receipt command line, retired alongside its header — see OMS2ReceiptCommand.Table.al for why the object
 * stays in the app instead of being deleted.
 */
table 80237 "OMS2 Receipt Command Line"
{
    Caption = 'OMS Receipt Command Line';
    DataClassification = CustomerContent;
    Access = Public;
    Extensible = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'OMS posts receipts through OMS2 Receipt Command Line V2.';
    ObsoleteTag = '1.1.2.21';

    fields
    {
        field(1; "OMS Receiving Ref. No."; Code[11])
        {
            Caption = 'OMS Receiving Ref. No.';
            DataClassification = CustomerContent;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }
        field(4; "Quantity to Receive"; Decimal)
        {
            Caption = 'Quantity to Receive';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(5; "Purchase Line No."; Integer)
        {
            Caption = 'Purchase Line No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "OMS Receiving Ref. No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
