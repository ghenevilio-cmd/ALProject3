page 80259 "OMS2 Receipt Cmd Lines V2 API"
{
    APIVersion = 'v2.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Receipt Command Line';
    EntitySetCaption = 'OMS Receipt Command Lines';
    EntityName = 'receiptCommandLine';
    EntitySetName = 'receiptCommandLines';
    PageType = API;
    SourceTable = "OMS2 Receipt Command Line V2";
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
                field(quantityToReceive; Rec."Quantity to Receive") { Caption = 'Quantity to Receive'; }
                field(purchaseLineNumber; Rec."Purchase Line No.") { Caption = 'Purchase Line Number'; }
            }
        }
    }
}
