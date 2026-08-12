table 80294 "TBGC APL Order History"
{
    Caption = 'APL Order History';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "History ID"; Guid)
        {
            Caption = 'History ID';
        }
        field(3; "Location Code"; Code[20])
        {
            Caption = 'Location Code';
        }
        field(4; "History Created At"; DateTime)
        {
            Caption = 'History Created At';
        }
        field(5; "User ID"; Code[50])
        {
            Caption = 'User ID';
        }
        field(7; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
        }
        field(8; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(9; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Brand Code"; Code[20])
        {
            Caption = 'Brand Code';
        }
        field(12; "Unit of Measure Code"; Code[20])
        {
            Caption = 'Unit of Measure Code';
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
        }
        field(17; "Brand Description"; Text[100])
        {
            Caption = 'Brand Description';
        }
        field(18; Selected; Boolean)
        {
            Caption = 'Selected';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(LocationHistory; "Location Code", "History Created At", "History ID")
        {
        }
        key(HistoryLookup; "History ID")
        {
        }
    }
}
