table 80255 "OMS2 Draft Command Line"
{
    Caption = 'OMS Draft Command Line';
    DataClassification = CustomerContent;
    Access = Public;
    Extensible = false;

    fields
    {
        field(1; "Command Id"; Guid) { Caption = 'Command Id'; TableRelation = "OMS2 Draft Command"."Command Id"; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Item No."; Code[20]) { Caption = 'Item No.'; TableRelation = Item."No."; }
        field(4; "Brand Code"; Code[20]) { Caption = 'Brand Code'; }
        field(5; "Unit of Measure Code"; Code[20]) { Caption = 'Unit of Measure Code'; }
        field(6; Quantity; Decimal) { Caption = 'Quantity'; DecimalPlaces = 0 : 5; }
        field(7; "Direct Unit Cost"; Decimal) { Caption = 'Direct Unit Cost'; DecimalPlaces = 0 : 5; }
    }

    keys
    {
        key(PK; "Command Id", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Command: Record "OMS2 Draft Command";
    begin
        Command.Get("Command Id");
        if Command.Status <> Command.Status::Open then
            Error('Draft command %1 is already complete.', "Command Id");
        TestField("Line No.");
        TestField("Item No.");
        TestField("Unit of Measure Code");
        if Quantity <= 0 then
            Error('Quantity must be greater than zero.');
        if "Direct Unit Cost" < 0 then
            Error('Direct Unit Cost cannot be negative.');
    end;
}
