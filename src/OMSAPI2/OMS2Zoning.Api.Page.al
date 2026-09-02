page 80243 "OMS2 Zoning API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityName = 'zone';
    EntitySetName = 'zones';
    EntityCaption = 'OMS Zone';
    EntitySetCaption = 'OMS Zones';
    PageType = API;
    SourceTable = "TBGC Zoning Table";
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(code; Rec."Zoning Code") { Caption = 'Code'; }
                field(displayName; Rec.Description) { Caption = 'Display Name'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; }
            }
        }
    }
}
