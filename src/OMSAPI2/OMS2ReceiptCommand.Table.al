/*
 * The v1 receipt command, retired.
 *
 * OMS posts receipts through the v2 command now, which carries the Business Central line number and the
 * receiving employee. Nothing reads or writes this table any more.
 *
 * It is marked Removed rather than deleted from the app: Business Central refuses an upgrade that drops a table,
 * because the data it holds would go with it. Keeping the object retires it safely — no code can reach it, and
 * the rows stay until a later version deletes the table deliberately. Its triggers and the relation to its line
 * table are gone, since a removed object cannot be referenced from anywhere.
 */
table 80236 "OMS2 Receipt Command"
{
    Caption = 'OMS Receipt Command';
    DataClassification = CustomerContent;
    Access = Public;
    Extensible = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'OMS posts receipts through OMS2 Receipt Command V2.';
    ObsoleteTag = '1.1.2.21';

    fields
    {
        field(1; "OMS Receiving Ref. No."; Code[11])
        {
            Caption = 'OMS Receiving Ref. No.';
            DataClassification = CustomerContent;
        }
        field(2; "OMS PO Ref. No."; Code[11])
        {
            Caption = 'OMS PO Ref. No.';
            DataClassification = CustomerContent;
        }
        field(3; "OMS Receiving Payload Hash"; Code[64])
        {
            Caption = 'OMS Receiving Payload Hash';
            DataClassification = SystemMetadata;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
            OptionMembers = Open,Posted,Failed;
            OptionCaption = 'Open,Posted,Failed';
        }
        field(6; "Purchase Order No."; Code[20])
        {
            Caption = 'Purchase Order No.';
            DataClassification = CustomerContent;
        }
        field(7; "Posted Receipt No."; Code[20])
        {
            Caption = 'Posted Receipt No.';
            DataClassification = CustomerContent;
        }
        field(8; "Posted Receipt Id"; Guid)
        {
            Caption = 'Posted Receipt Id';
            DataClassification = SystemMetadata;
        }
        field(9; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(10; "Posted At"; DateTime)
        {
            Caption = 'Posted At';
            DataClassification = SystemMetadata;
        }
        field(11; "Purchase Order Id"; Guid)
        {
            Caption = 'Purchase Order Id';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "OMS Receiving Ref. No.")
        {
            Clustered = true;
        }
        key(PurchaseOrder; "OMS PO Ref. No.")
        {
        }
    }
}
