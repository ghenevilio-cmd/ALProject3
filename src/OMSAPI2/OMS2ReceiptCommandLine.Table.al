table 80237 "OMS2 Receipt Command Line"
{
    Caption = 'OMS Receipt Command Line';
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
            TableRelation = "OMS2 Receipt Command"."OMS Receiving Ref. No.";
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
            TableRelation = Item."No.";
        }
        field(4; "Quantity to Receive"; Decimal)
        {
            Caption = 'Quantity to Receive';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        /** Set when OMS knows the exact purchase line; otherwise the item number resolves it. */
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

    trigger OnInsert()
    var
        ReceiptCommand: Record "OMS2 Receipt Command";
        LastLine: Record "OMS2 Receipt Command Line";
        ItemRequiredErr: Label 'Item No. is required.';
        QuantityRequiredErr: Label 'Quantity to Receive must be greater than zero.';
        CommandClosedErr: Label 'Receipt command %1 is no longer open.';
    begin
        ReceiptCommand.Get("OMS Receiving Ref. No.");
        if ReceiptCommand.Status <> ReceiptCommand.Status::Open then
            Error(CommandClosedErr, "OMS Receiving Ref. No.");
        if "Item No." = '' then
            Error(ItemRequiredErr);
        if "Quantity to Receive" <= 0 then
            Error(QuantityRequiredErr);

        if "Line No." = 0 then begin
            LastLine.SetRange("OMS Receiving Ref. No.", "OMS Receiving Ref. No.");
            if LastLine.FindLast() then
                "Line No." := LastLine."Line No." + 10000
            else
                "Line No." := 10000;
        end;
    end;
}
