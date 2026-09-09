tableextension 80226 "OMS2 Purch Rcpt Header" extends "Purch. Rcpt. Header"
{
    fields
    {
        field(80206; "OMS PO Ref. No."; Code[11])
        {
            Caption = 'OMS PO Ref. No.';
            DataClassification = CustomerContent;
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'OMS now correlates receipts by Business Central document identities.';
            ObsoleteTag = '1.1.2.16';
        }
        field(80207; "OMS Receiving Ref. No."; Code[11])
        {
            Caption = 'OMS Receiving Ref. No.';
            DataClassification = CustomerContent;
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'OMS now stores the official Business Central Posted Receipt No.';
            ObsoleteTag = '1.1.2.16';
        }
        field(80208; "OMS PO Payload Hash"; Code[64])
        {
            Caption = 'OMS PO Payload Hash';
            DataClassification = SystemMetadata;
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'OMS v2 stores replay hashes in its technical command table.';
            ObsoleteTag = '1.1.2.16';
        }
        field(80209; "OMS Receiving Payload Hash"; Code[64])
        {
            Caption = 'OMS Receiving Payload Hash';
            DataClassification = SystemMetadata;
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'OMS v2 stores replay hashes in its technical command table.';
            ObsoleteTag = '1.1.2.16';
        }
    }
}
