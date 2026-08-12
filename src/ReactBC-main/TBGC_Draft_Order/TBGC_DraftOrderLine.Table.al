table 80209 "TBGC Draft Order Line"
{
    Caption = 'Draft Order Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "TBGC Draft Order Header"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; "TBGC Brand Code"; Code[20])
        {
            Caption = 'TBGC Brand Code';
        }
        field(7; "TBGC Brand Description"; Text[100])
        {
            Caption = 'TBGC Brand Description';
        }
        field(8; "Unit of Measure Code"; Code[20])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure".Code;
        }
        field(9; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(10; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Brand Description"; Text[100])
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'No longer used. Replaced by the correct brand field.';
            ObsoleteTag = '1.0.0.4';
        }
        field(12; "Brand Code"; Code[20])
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'No longer used. Replaced by the correct brand field.';
            ObsoleteTag = '1.0.0.4';
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
