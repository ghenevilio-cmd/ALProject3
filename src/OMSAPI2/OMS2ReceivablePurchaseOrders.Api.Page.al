page 80245 "OMS2 Receivable POs API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Receivable Purchase Order';
    EntitySetCaption = 'OMS Receivable Purchase Orders';
    EntityName = 'receivablePurchaseOrder';
    EntitySetName = 'receivablePurchaseOrders';
    PageType = API;
    SourceTable = "Purchase Header";
    SourceTableView = where("Document Type" = const(Order));
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;
    AboutText = 'Reads OMS purchase orders back so OMS can show what is still outstanding to receive.';

    // Every field binds straight to Rec. Page 80231 creates orders and binds its OMS reference to a page
    // variable, which OData cannot filter on; a caller looking an order up by that reference must use this
    // page instead.

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
                field(omsPayloadHash; Rec."OMS PO Payload Hash")
                {
                    Caption = 'OMS Payload Hash';
                }
                field(vendorNumber; Rec."Buy-from Vendor No.")
                {
                    Caption = 'Vendor Number';
                }
                field(vendorName; Rec."Buy-from Vendor Name")
                {
                    Caption = 'Vendor Name';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(orderDate; Rec."Order Date")
                {
                    Caption = 'Order Date';
                }
                field(expectedReceiptDate; Rec."Expected Receipt Date")
                {
                    Caption = 'Expected Receipt Date';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(totalAmount; Rec.Amount)
                {
                    Caption = 'Total Amount';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
                part(receivablePurchaseOrderLines; "OMS2 Receivable PO Lines API")
                {
                    Caption = 'Receivable Purchase Order Lines';
                    EntityName = 'receivablePurchaseOrderLine';
                    EntitySetName = 'receivablePurchaseOrderLines';
                    SubPageLink = "Document Type" = const(Order), "Document No." = field("No.");
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
    end;
}
