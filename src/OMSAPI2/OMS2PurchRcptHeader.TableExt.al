tableextension 80226 "OMS2 Purch Rcpt Header" extends "Purch. Rcpt. Header"
{
    fields
    {
        field(80206; "OMS PO Ref. No."; Code[11])
        {
            Caption = 'OMS PO Ref. No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(80207; "OMS Receiving Ref. No."; Code[11])
        {
            Caption = 'OMS Receiving Ref. No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(80208; "OMS PO Payload Hash"; Code[64])
        {
            Caption = 'OMS PO Payload Hash';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(80209; "OMS Receiving Payload Hash"; Code[64])
        {
            Caption = 'OMS Receiving Payload Hash';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
}
