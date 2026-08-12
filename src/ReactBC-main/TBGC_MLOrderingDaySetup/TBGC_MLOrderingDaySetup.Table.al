table 80220 "TBGC ML Ordering Day Setup"
{
    Caption = 'ML Ordering Day Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Allow Monday"; Boolean)
        {
            Caption = 'Allow Monday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(3; "Allow Tuesday"; Boolean)
        {
            Caption = 'Allow Tuesday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(4; "Allow Wednesday"; Boolean)
        {
            Caption = 'Allow Wednesday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(5; "Allow Thursday"; Boolean)
        {
            Caption = 'Allow Thursday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(6; "Allow Friday"; Boolean)
        {
            Caption = 'Allow Friday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(7; "Allow Saturday"; Boolean)
        {
            Caption = 'Allow Saturday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(8; "Allow Sunday"; Boolean)
        {
            Caption = 'Allow Sunday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(9; "Draft Allow Monday"; Boolean)
        {
            Caption = 'Draft Allow Monday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(10; "Draft Allow Tuesday"; Boolean)
        {
            Caption = 'Draft Allow Tuesday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(11; "Draft Allow Wednesday"; Boolean)
        {
            Caption = 'Draft Allow Wednesday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(12; "Draft Allow Thursday"; Boolean)
        {
            Caption = 'Draft Allow Thursday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(13; "Draft Allow Friday"; Boolean)
        {
            Caption = 'Draft Allow Friday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(14; "Draft Allow Saturday"; Boolean)
        {
            Caption = 'Draft Allow Saturday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(15; "Draft Allow Sunday"; Boolean)
        {
            Caption = 'Draft Allow Sunday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(16; "Allow From Time"; Time)
        {
            Caption = 'Allow From Time';
            DataClassification = CustomerContent;
        }
        field(17; "Allow To Time"; Time)
        {
            Caption = 'Allow To Time';
            DataClassification = CustomerContent;
        }
        field(18; "Draft Allow From Time"; Time)
        {
            Caption = 'Draft Allow From Time';
            DataClassification = CustomerContent;
        }
        field(19; "Draft Allow To Time"; Time)
        {
            Caption = 'Draft Allow To Time';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
