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
        field(14; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(80206; "OMS PO Ref. No."; Code[11])
        {
            Caption = 'OMS PO Ref. No.';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'OMS now correlates this document by its Business Central Draft Order No.';
            ObsoleteTag = '1.1.2.21';
        }
        field(80207; "OMS Currency Code"; Code[10])
        {
            Caption = 'OMS Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency.Code;
        }
        field(80208; "OMS PO Payload Hash"; Code[64])
        {
            Caption = 'OMS PO Payload Hash';
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'OMS v2 stores replay hashes in its technical command table.';
            ObsoleteTag = '1.1.2.21';
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
        // Indexed the retired OMS reference, which nothing looks a document up by any more.
        key(OMSReference; "OMS PO Ref. No.")
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'OMS now correlates this document by its Business Central Draft Order No.';
            ObsoleteTag = '1.1.2.21';
        }
    }

    trigger OnInsert()
    begin
        if "No." = '' then begin
            PurchasesPayablesSetup.SetLoadFields("TBGC Draft Order Nos.");
            PurchasesPayablesSetup.Get();
            PurchasesPayablesSetup.TestField("TBGC Draft Order Nos.");
            "No. Series" := PurchasesPayablesSetup."TBGC Draft Order Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;

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

    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
}
