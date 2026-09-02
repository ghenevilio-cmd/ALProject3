page 80241 "OMS2 Concepts API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityName = 'concept';
    EntitySetName = 'concepts';
    EntityCaption = 'OMS Concept';
    EntitySetCaption = 'OMS Concepts';
    PageType = API;
    SourceTable = "TBGC Concept Table";
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
                field(code; Rec."Concept Code") { Caption = 'Code'; }
                field(displayName; Rec.Description) { Caption = 'Display Name'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; }
            }
        }
    }
}
