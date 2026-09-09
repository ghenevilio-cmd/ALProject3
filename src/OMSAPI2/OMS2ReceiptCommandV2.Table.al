table 80258 "OMS2 Receipt Command V2"
{
    Caption = 'OMS Receipt Command V2';
    DataClassification = CustomerContent;
    Access = Public;
    Extensible = false;

    fields
    {
        field(1; "Command Id"; Guid) { Caption = 'Command Id'; DataClassification = SystemMetadata; }
        field(2; "Payload Hash"; Code[64]) { Caption = 'Payload Hash'; DataClassification = SystemMetadata; }
        field(3; "Purchase Order Id"; Guid) { Caption = 'Purchase Order Id'; DataClassification = SystemMetadata; }
        field(4; "Posting Date"; Date) { Caption = 'Posting Date'; }
        field(5; Status; Option) { Caption = 'Status'; OptionMembers = Open,Posted; Editable = false; }
        field(6; "Purchase Order No."; Code[20]) { Caption = 'Purchase Order No.'; Editable = false; }
        field(7; "Posted Receipt No."; Code[20]) { Caption = 'Posted Receipt No.'; Editable = false; }
        field(8; "Posted Receipt Id"; Guid) { Caption = 'Posted Receipt Id'; Editable = false; }
        field(9; "Created At"; DateTime) { Caption = 'Created At'; Editable = false; }
        field(10; "Completed At"; DateTime) { Caption = 'Completed At'; Editable = false; }
    }

    keys
    {
        key(PK; "Command Id") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if IsNullGuid("Command Id") then
            Error('Command Id is required.');
        if IsNullGuid("Purchase Order Id") then
            Error('Purchase Order Id is required.');
        if (StrLen("Payload Hash") <> MaxStrLen("Payload Hash")) or
           (DelChr("Payload Hash", '=', '0123456789ABCDEF') <> '')
        then
            Error('Payload Hash must be 64 hexadecimal characters.');
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();
        Status := Status::Open;
        "Created At" := CurrentDateTime();
    end;

    trigger OnDelete()
    var
        Line: Record "OMS2 Receipt Command Line V2";
    begin
        if Status = Status::Posted then
            Error('A posted receipt command cannot be deleted.');
        Line.SetRange("Command Id", "Command Id");
        Line.DeleteAll(true);
    end;
}
