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
                field(orderNumber; Rec."Order No.")
                {
                    Caption = 'Order Number';
                }
                // Who counted the delivery in: D365-WEB-<employee> from OMS, D365-MOB-<employee> from the
                // mobile application, and the Business Central user for a receipt posted at a desk. A buyer
                // asking who received a delivery is asking about the person, not about which system was used.
                field(receivedBy; Rec."TBGC Original Created By")
                {
                    Caption = 'Received By';
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
        /*
         * Every receipt posted against a purchase order, whoever posted it.
         *
         * This used to select receipts carrying an OMS receiving reference. That reference was retired when
         * Business Central became the owner of document identities, so nothing has set it since — the page
         * answered with pre-cutover receipts only, and a delivery counted in on the mobile application was
         * invisible to OMS even though its quantities had already moved the order to partially received.
         *
         * The order number is the correlation OMS needs and the one a receipt always carries.
         */
        Rec.SetFilter("Order No.", '<>%1', '');
    end;
}
