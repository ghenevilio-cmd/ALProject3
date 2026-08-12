table 80221 "TBGC Draft Price Update Buf"
{
    Caption = 'Draft Price Update Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Draft Order No."; Code[20])
        {
            Caption = 'Draft Order No.';
        }
        field(3; "Draft Line No."; Integer)
        {
            Caption = 'Draft Line No.';
        }
        field(4; "Released Date"; Date)
        {
            Caption = 'Released Date';
        }
        field(5; "Location Code"; Code[20])
        {
            Caption = 'Location Code';
        }
        field(6; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
        }
        field(7; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Unit of Measure Code"; Code[20])
        {
            Caption = 'Unit of Measure Code';
        }
        field(10; "TBGC Brand Code"; Code[20])
        {
            Caption = 'Brand Code';
        }
        field(11; "TBGC Zoning Code"; Code[20])
        {
            Caption = 'Zoning Code';
        }
        field(12; "TBGC Concept Code"; Code[20])
        {
            Caption = 'Concept Code';
        }
        field(13; "TBGC City"; Text[50])
        {
            Caption = 'City';
        }
        field(14; "Current Draft Price"; Decimal)
        {
            Caption = 'Current Draft Price';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Latest APL Price"; Decimal)
        {
            Caption = 'Latest APL Price';
            DecimalPlaces = 0 : 5;
        }
        field(16; Difference; Decimal)
        {
            Caption = 'Difference';
            DecimalPlaces = 0 : 5;
        }
        field(17; "APL Starting Date"; Date)
        {
            Caption = 'APL Starting Date';
        }
        field(18; "APL Entry No."; Integer)
        {
            Caption = 'APL Entry No.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(DraftLine; "Draft Order No.", "Draft Line No.")
        {
        }
    }
}
