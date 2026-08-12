table 80208 "TBGC Draft Order Header"
{
    Caption = 'Draft Order Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Location Code"; Code[20])
        {
            Caption = 'Location Code';
        }
        field(3; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(4; "Created By User ID"; Code[50])
        {
            Caption = 'Created By User ID';
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Archived,Converted';
            OptionMembers = Open,Archived,Converted;
        }
        field(6; "Expected Receipt Date"; Date)
        {
            Caption = 'Need by Date';
        }
        field(7; "Released Date"; Date)
        {
            Caption = 'Released Date';

            trigger OnValidate()
            var
                ReleasedDateMgt: Codeunit "TBGC Released Date Mgt";
            begin
                ReleasedDateMgt.ValidateReleasedDate("Released Date");

                if ("Expected Receipt Date" <> 0D) and ("Released Date" > "Expected Receipt Date") then
                    Error('Need by Date cannot be earlier than Released Date. Need by Date is %1.', "Expected Receipt Date");
            end;
        }
        field(8; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
        }
        field(9; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Draft,Checkout';
            OptionMembers = Draft,Checkout;
        }
        field(10; "Last Error Message"; Text[250])
        {
            Caption = 'Last Error Message';
        }
        field(11; "Auto Convert In Progress"; Boolean)
        {
            Caption = 'Auto Convert In Progress';
        }
        field(12; "Auto Convert Started At"; DateTime)
        {
            Caption = 'Auto Convert Started At';
        }
        field(13; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(LocationStatus; "Location Code", Status, "Created At")
        {
        }
    }

    trigger OnInsert()
    begin
        if "No." = '' then
            "No." := GetNextDraftNo();

        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();

        if "Created By User ID" = '' then
            "Created By User ID" := CopyStr(UserId(), 1, MaxStrLen("Created By User ID"));
    end;

    trigger OnDelete()
    var
        DraftOrderLine: Record "TBGC Draft Order Line";
    begin
        DraftOrderLine.SetRange("Document No.", "No.");
        if not DraftOrderLine.IsEmpty() then
            DraftOrderLine.DeleteAll();
    end;

    local procedure GetNextDraftNo(): Code[20]
    var
        DraftOrderHeader: Record "TBGC Draft Order Header";
        LastNoInteger: Integer;
        DraftSequenceText: Text;
    begin
        DraftOrderHeader.SetCurrentKey("No.");
        if DraftOrderHeader.FindLast() then
            Evaluate(LastNoInteger, DelChr(DraftOrderHeader."No.", '=', 'DRF-'));

        LastNoInteger += 1;
        DraftSequenceText := Format(LastNoInteger);
        while StrLen(DraftSequenceText) < 6 do
            DraftSequenceText := '0' + DraftSequenceText;

        exit(CopyStr('DRF-' + DraftSequenceText, 1, 20));
    end;
}
