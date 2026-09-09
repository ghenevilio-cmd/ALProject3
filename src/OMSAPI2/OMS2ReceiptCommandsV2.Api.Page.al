page 80258 "OMS2 Receipt Commands V2 API"
{
    APIVersion = 'v2.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Receipt Command';
    EntitySetCaption = 'OMS Receipt Commands';
    EntityName = 'receiptCommand';
    EntitySetName = 'receiptCommands';
    PageType = API;
    SourceTable = "OMS2 Receipt Command V2";
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
                field(purchaseOrderId; Rec."Purchase Order Id") { Caption = 'Purchase Order Id'; }
                field(postingDate; Rec."Posting Date") { Caption = 'Posting Date'; }
                field(status; Rec.Status) { Caption = 'Status'; Editable = false; }
                field(purchaseOrderNumber; Rec."Purchase Order No.") { Caption = 'Purchase Order Number'; Editable = false; }
                field(postedReceiptNumber; Rec."Posted Receipt No.") { Caption = 'Posted Receipt Number'; Editable = false; }
                field(postedReceiptId; Rec."Posted Receipt Id") { Caption = 'Posted Receipt Id'; Editable = false; }
                field(completedAt; Rec."Completed At") { Caption = 'Completed At'; Editable = false; }
                part(lines; "OMS2 Receipt Cmd Lines V2 API")
                {
                    Caption = 'Lines';
                    EntityName = 'receiptCommandLine';
                    EntitySetName = 'receiptCommandLines';
                    SubPageLink = "Command Id" = field("Command Id");
                }
            }
        }
    }

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure Post(var ActionContext: WebServiceActionContext)
    var
        CommandMgt: Codeunit "OMS2 Command Mgt V2";
    begin
        if not BindSubscription(CommandMgt) then
            Error('The receipt result listener could not be started. Nothing was posted.');
        CommandMgt.PostReceipt(Rec);
        UnbindSubscription(CommandMgt);
        Rec.Get(Rec."Command Id");
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"OMS2 Receipt Commands V2 API");
        ActionContext.AddEntityKey(Rec.FieldNo("Command Id"), Rec."Command Id");
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
