tableextension 80225 "OMS2 Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(80206; "OMS PO Ref. No."; Code[11])
        {
            Caption = 'OMS PO Ref. No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateReference("OMS PO Ref. No.", FieldCaption("OMS PO Ref. No."));
            end;
        }
        field(80207; "OMS Receiving Ref. No."; Code[11])
        {
            Caption = 'OMS Receiving Ref. No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateReference("OMS Receiving Ref. No.", FieldCaption("OMS Receiving Ref. No."));
            end;
        }
        field(80208; "OMS PO Payload Hash"; Code[64])
        {
            Caption = 'OMS PO Payload Hash';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                ValidateHash("OMS PO Payload Hash", FieldCaption("OMS PO Payload Hash"));
            end;
        }
        field(80209; "OMS Receiving Payload Hash"; Code[64])
        {
            Caption = 'OMS Receiving Payload Hash';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                ValidateHash("OMS Receiving Payload Hash", FieldCaption("OMS Receiving Payload Hash"));
            end;
        }
    }

    trigger OnBeforeInsert()
    var
        ExistingPurchaseHeader: Record "Purchase Header";
        DuplicateReferenceErr: Label 'OMS PO reference %1 already belongs to purchase order %2.';
        ChangedReplayErr: Label 'OMS PO reference %1 was already used with a different payload.';
    begin
        if "OMS PO Ref. No." = '' then
            exit;

        TestField("OMS PO Payload Hash");
        // ponytail: the short header insert is serialized; replace with an integration ledger only if measured contention requires it.
        ExistingPurchaseHeader.LockTable();
        ExistingPurchaseHeader.SetRange("Document Type", ExistingPurchaseHeader."Document Type"::Order);
        ExistingPurchaseHeader.SetRange("OMS PO Ref. No.", "OMS PO Ref. No.");
        if not ExistingPurchaseHeader.FindFirst() then
            exit;

        if ExistingPurchaseHeader."OMS PO Payload Hash" <> "OMS PO Payload Hash" then
            Error(ChangedReplayErr, "OMS PO Ref. No.");

        Error(DuplicateReferenceErr, "OMS PO Ref. No.", ExistingPurchaseHeader."No.");
    end;

    local procedure ValidateReference(Reference: Code[11]; ReferenceCaption: Text)
    var
        InvalidReferenceErr: Label '%1 must contain only uppercase letters and numbers.';
    begin
        if Reference = '' then
            exit;

        if (Reference <> UpperCase(Reference)) or
           (DelChr(Reference, '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') <> '')
        then
            Error(InvalidReferenceErr, ReferenceCaption);
    end;

    local procedure ValidateHash(HashValue: Code[64]; HashCaption: Text)
    var
        InvalidHashErr: Label '%1 must be a 64-character hexadecimal SHA-256 value.';
    begin
        if HashValue = '' then
            exit;

        if (StrLen(HashValue) <> MaxStrLen(HashValue)) or
           (DelChr(HashValue, '=', '0123456789ABCDEF') <> '')
        then
            Error(InvalidHashErr, HashCaption);
    end;
}
