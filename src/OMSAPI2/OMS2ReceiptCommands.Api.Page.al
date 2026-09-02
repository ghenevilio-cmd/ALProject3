page 80238 "OMS2 Receipt Commands API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Receipt Command';
    EntitySetCaption = 'OMS Receipt Commands';
    EntityName = 'receiptCommand';
    EntitySetName = 'receiptCommands';
    PageType = API;
    SourceTable = "OMS2 Receipt Command";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ChangeTrackingAllowed = true;
    Extensible = false;
    AboutText = 'Receives a purchase order with the quantities entered in OMS, then posts them receive-only.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(omsReceivingReferenceNo; Rec."OMS Receiving Ref. No.")
                {
                    Caption = 'OMS Receiving Reference Number';
                }
                field(omsPoReferenceNo; Rec."OMS PO Ref. No.")
                {
                    Caption = 'OMS PO Reference Number';
                    Editable = false;
                }
                field(purchaseOrderId; Rec."Purchase Order Id")
                {
                    Caption = 'Purchase Order Id';
                }
                field(omsPayloadHash; Rec."OMS Receiving Payload Hash")
                {
                    Caption = 'OMS Payload Hash';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(purchaseOrderNumber; Rec."Purchase Order No.")
                {
                    Caption = 'Purchase Order Number';
                    Editable = false;
                }
                field(postedReceiptNumber; Rec."Posted Receipt No.")
                {
                    Caption = 'Posted Receipt Number';
                    Editable = false;
                }
                field(postedReceiptId; Rec."Posted Receipt Id")
                {
                    Caption = 'Posted Receipt Id';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(receiptCommandLines; "OMS2 Receipt Command Lines API")
                {
                    Caption = 'Receipt Command Lines';
                    EntityName = 'receiptCommandLine';
                    EntitySetName = 'receiptCommandLines';
                    SubPageLink = "OMS Receiving Ref. No." = field("OMS Receiving Ref. No.");
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
    end;

    /**
     * Posting is a separate call so OMS can send the header, then its lines, then commit the whole receipt.
     * Re-posting the same command is a no-op that returns the identities Business Central already assigned.
     */
    [ServiceEnabled]
    [Scope('Cloud')]
    procedure Post(var ActionContext: WebServiceActionContext)
    var
        ReceiptCommand: Record "OMS2 Receipt Command";
        CommandMgt: Codeunit "OMS2 Command Mgt";
    begin
        ReceiptCommand.Get(Rec."OMS Receiving Ref. No.");
        CommandMgt.PostReceipt(ReceiptCommand);

        Rec.Get(ReceiptCommand."OMS Receiving Ref. No.");
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"OMS2 Receipt Commands API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
