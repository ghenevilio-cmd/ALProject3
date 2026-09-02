table 80236 "OMS2 Receipt Command"
{
    Caption = 'OMS Receipt Command';
    DataClassification = CustomerContent;
    Access = Public;
    Extensible = false;

    fields
    {
        field(1; "OMS Receiving Ref. No."; Code[11])
        {
            Caption = 'OMS Receiving Ref. No.';
            DataClassification = CustomerContent;
            NotBlank = true;
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
            Editable = false;
        }
        field(6; "Purchase Order No."; Code[20])
        {
            Caption = 'Purchase Order No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
        }
        field(7; "Posted Receipt No."; Code[20])
        {
            Caption = 'Posted Receipt No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8; "Posted Receipt Id"; Guid)
        {
            Caption = 'Posted Receipt Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Posted At"; DateTime)
        {
            Caption = 'Posted At';
            DataClassification = SystemMetadata;
            Editable = false;
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

    /**
     * The primary key is the OMS receiving reference, so this table is the idempotency store the contract
     * requires: one stored result per company, operation and key. A repeat of the same command finds its own
     * row and returns the original Business Central identities instead of posting a second receipt.
     */
    trigger OnInsert()
    var
        InvalidHashErr: Label 'OMS Receiving Payload Hash must be 64 hexadecimal characters.';
        PurchaseOrderRequiredErr: Label 'Purchase Order Id is required.';
    begin
        if IsNullGuid("Purchase Order Id") then
            Error(PurchaseOrderRequiredErr);
        if (StrLen("OMS Receiving Payload Hash") <> MaxStrLen("OMS Receiving Payload Hash")) or
           (DelChr("OMS Receiving Payload Hash", '=', '0123456789ABCDEF') <> '')
        then
            Error(InvalidHashErr);

        Status := Status::Open;
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();
    end;

    trigger OnDelete()
    var
        ReceiptCommandLine: Record "OMS2 Receipt Command Line";
        PostedDeleteErr: Label 'A posted receipt command cannot be deleted.';
    begin
        if Status = Status::Posted then
            Error(PostedDeleteErr);

        ReceiptCommandLine.SetRange("OMS Receiving Ref. No.", "OMS Receiving Ref. No.");
        ReceiptCommandLine.DeleteAll(true);
    end;
}
