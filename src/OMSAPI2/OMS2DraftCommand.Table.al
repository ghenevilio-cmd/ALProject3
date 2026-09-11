table 80249 "OMS2 Draft Command"
{
    Caption = 'OMS Draft Command';
    DataClassification = CustomerContent;
    Access = Public;
    Extensible = false;

    fields
    {
        field(1; "Command Id"; Guid) { Caption = 'Command Id'; DataClassification = SystemMetadata; }
        field(2; "Payload Hash"; Code[64]) { Caption = 'Payload Hash'; DataClassification = SystemMetadata; }
        field(3; "Vendor No."; Code[20]) { Caption = 'Vendor No.'; TableRelation = Vendor."No."; }
        field(4; "Currency Code"; Code[10]) { Caption = 'Currency Code'; TableRelation = Currency.Code; }
        field(5; "Location Code"; Code[20]) { Caption = 'Location Code'; TableRelation = Location.Code; }
        field(6; "Expected Receipt Date"; Date) { Caption = 'Expected Receipt Date'; }
        field(7; Status; Option) { Caption = 'Status'; OptionMembers = Open,Created; Editable = false; }
        field(8; "Draft Order No."; Code[20]) { Caption = 'Draft Order No.'; Editable = false; }
        field(9; "Draft Order Id"; Guid) { Caption = 'Draft Order Id'; Editable = false; }
        field(10; "Created At"; DateTime) { Caption = 'Created At'; Editable = false; }
        field(11; "Completed At"; DateTime) { Caption = 'Completed At'; Editable = false; }
        field(12; "Created By User ID"; Code[50]) { Caption = 'Created By User ID'; }
    }

    keys
    {
        key(PK; "Command Id") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if IsNullGuid("Command Id") then
            Error('Command Id is required.');
        if (StrLen("Payload Hash") <> MaxStrLen("Payload Hash")) or
           (DelChr("Payload Hash", '=', '0123456789ABCDEF') <> '')
        then
            Error('Payload Hash must be 64 hexadecimal characters.');
        TestField("Vendor No.");
        TestField("Currency Code");
        TestField("Location Code");
        TestField("Expected Receipt Date");
        Status := Status::Open;
        "Created At" := CurrentDateTime();
    end;

    trigger OnDelete()
    var
        Line: Record "OMS2 Draft Command Line";
    begin
        if Status = Status::Created then
            Error('A completed Draft command cannot be deleted.');
        Line.SetRange("Command Id", "Command Id");
        Line.DeleteAll(true);
    end;
}
