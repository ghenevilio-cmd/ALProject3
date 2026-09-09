table 80259 "OMS2 Receipt Command Line V2"
{
    Caption = 'OMS Receipt Command Line V2';
    DataClassification = CustomerContent;
    Access = Public;
    Extensible = false;

    fields
    {
        field(1; "Command Id"; Guid) { Caption = 'Command Id'; TableRelation = "OMS2 Receipt Command V2"."Command Id"; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Item No."; Code[20]) { Caption = 'Item No.'; TableRelation = Item."No."; }
        field(4; "Quantity to Receive"; Decimal) { Caption = 'Quantity to Receive'; DecimalPlaces = 0 : 5; MinValue = 0; }
        field(5; "Purchase Line No."; Integer) { Caption = 'Purchase Line No.'; }
    }

    keys
    {
        key(PK; "Command Id", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Command: Record "OMS2 Receipt Command V2";
    begin
        Command.Get("Command Id");
        if Command.Status <> Command.Status::Open then
            Error('Receipt command %1 is already complete.', "Command Id");
        TestField("Line No.");
        TestField("Item No.");
        if "Quantity to Receive" <= 0 then
            Error('Quantity to Receive must be greater than zero.');
    end;
}
