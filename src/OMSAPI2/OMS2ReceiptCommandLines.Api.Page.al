page 80239 "OMS2 Receipt Command Lines API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Receipt Command Line';
    EntitySetCaption = 'OMS Receipt Command Lines';
    EntityName = 'receiptCommandLine';
    EntitySetName = 'receiptCommandLines';
    PageType = API;
    SourceTable = "OMS2 Receipt Command Line";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Carries the quantity received for one item, exactly as it was entered in OMS.';

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
                field(lineNumber; Rec."Line No.")
                {
                    Caption = 'Line Number';
                }
                field(itemNumber; Rec."Item No.")
                {
                    Caption = 'Item Number';
                }
                field(quantityToReceive; Rec."Quantity to Receive")
                {
                    Caption = 'Quantity to Receive';
                }
                field(purchaseLineNumber; Rec."Purchase Line No.")
                {
                    Caption = 'Purchase Line Number';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }
}
