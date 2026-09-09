page 80256 "OMS2 Draft Commands V2 API"
{
    APIVersion = 'v2.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Draft Command';
    EntitySetCaption = 'OMS Draft Commands';
    EntityName = 'draftCommand';
    EntitySetName = 'draftCommands';
    PageType = API;
    SourceTable = "OMS2 Draft Command";
    DelayedInsert = true;
    ODataKeyFields = "Command Id";
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ChangeTrackingAllowed = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(commandId; Rec."Command Id") { Caption = 'Command Id'; }
                field(payloadHash; Rec."Payload Hash") { Caption = 'Payload Hash'; }
                field(vendorNumber; Rec."Vendor No.") { Caption = 'Vendor Number'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'Currency Code'; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code'; }
                field(expectedReceiptDate; Rec."Expected Receipt Date") { Caption = 'Expected Receipt Date'; }
                field(status; Rec.Status) { Caption = 'Status'; Editable = false; }
                field(draftOrderNumber; Rec."Draft Order No.") { Caption = 'Draft Order Number'; Editable = false; }
                field(draftOrderId; Rec."Draft Order Id") { Caption = 'Draft Order Id'; Editable = false; }
                field(completedAt; Rec."Completed At") { Caption = 'Completed At'; Editable = false; }
                part(lines; "OMS2 Draft Cmd Lines V2 API")
                {
                    Caption = 'Lines';
                    EntityName = 'draftCommandLine';
                    EntitySetName = 'draftCommandLines';
                    SubPageLink = "Command Id" = field("Command Id");
                }
            }
        }
    }

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure CreateDraft(var ActionContext: WebServiceActionContext)
    var
        CommandMgt: Codeunit "OMS2 Command Mgt V2";
    begin
        CommandMgt.CreateDraft(Rec);
        Rec.Get(Rec."Command Id");
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"OMS2 Draft Commands V2 API");
        ActionContext.AddEntityKey(Rec.FieldNo("Command Id"), Rec."Command Id");
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
