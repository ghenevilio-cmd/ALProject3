page 80242 "OMS2 Stores API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityName = 'store';
    EntitySetName = 'stores';
    EntityCaption = 'OMS Store';
    EntitySetCaption = 'OMS Stores';
    PageType = API;
    SourceTable = "LSC Store";
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
                field(number; Rec."No.") { Caption = 'Number'; }
                field(code; Rec."Location Code") { Caption = 'Location Code'; }
                field(displayName; Rec.Name) { Caption = 'Display Name'; }
                field(conceptCode; Rec."TBGC Concept Code") { Caption = 'Concept Code'; }
                field(zoningCode; Rec."TBGC Zoning Code") { Caption = 'Zoning Code'; }
                field(city; Rec.City) { Caption = 'City'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; }
            }
        }
    }
}
