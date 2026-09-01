page 80235 "OMS2 Purchase Receipts API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Purchase Receipt';
    EntitySetCaption = 'OMS Purchase Receipts';
    EntityName = 'purchaseReceipt';
    EntitySetName = 'purchaseReceipts';
    PageType = API;
    SourceTable = "Purch. Rcpt. Header";
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;
    AboutText = 'Returns the official posted purchase receipts that carry an OMS receiving reference.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                }
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(omsPoReferenceNo; Rec."OMS PO Ref. No.")
                {
                    Caption = 'OMS PO Reference Number';
                }
                field(omsReceivingReferenceNo; Rec."OMS Receiving Ref. No.")
                {
                    Caption = 'OMS Receiving Reference Number';
                }
                field(orderNumber; Rec."Order No.")
                {
                    Caption = 'Order Number';
                }
                field(vendorNumber; Rec."Buy-from Vendor No.")
                {
                    Caption = 'Vendor Number';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
        // One OMS order can produce several partial receipts, so the OMS reference is a filter, never a key.
        Rec.SetFilter("OMS Receiving Ref. No.", '<>%1', '');
    end;
}
