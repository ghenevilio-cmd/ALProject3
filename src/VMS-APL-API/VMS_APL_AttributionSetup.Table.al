table 80268 "VMS APL Attribution Setup"
{
    Caption = 'VMS APL Employee Attribution Setup';
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; Enabled; Boolean) { }
        field(3; "Integration User Security ID"; Guid)
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Security ID";
        }
    }
    keys { key(PK; "Primary Key") { Clustered = true; } }
}
