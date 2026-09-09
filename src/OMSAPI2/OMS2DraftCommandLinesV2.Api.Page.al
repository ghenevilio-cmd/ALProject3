page 80257 "OMS2 Draft Cmd Lines V2 API"
{
    APIVersion = 'v2.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Draft Command Line';
    EntitySetCaption = 'OMS Draft Command Lines';
    EntityName = 'draftCommandLine';
    EntitySetName = 'draftCommandLines';
    PageType = API;
    SourceTable = "OMS2 Draft Command Line";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(commandId; Rec."Command Id") { Caption = 'Command Id'; }
                field(lineNumber; Rec."Line No.") { Caption = 'Line Number'; }
                field(itemNumber; Rec."Item No.") { Caption = 'Item Number'; }
                field(brandCode; Rec."Brand Code") { Caption = 'Brand Code'; }
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { Caption = 'Unit of Measure Code'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(directUnitCost; Rec."Direct Unit Cost") { Caption = 'Direct Unit Cost'; }
            }
        }
    }
}
