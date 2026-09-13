page 80247 "OMS2 Draft Orders API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Draft Order';
    EntitySetCaption = 'OMS Draft Orders';
    EntityName = 'draftOrder';
    EntitySetName = 'draftOrders';
    PageType = API;
    SourceTable = "TBGC Draft Order Header";
    SourceTableView = where(Type = const(Checkout));
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ChangeTrackingAllowed = true;
    Extensible = false;
    AboutText = 'Creates idempotent TBGC Draft Orders for conversion by the standard Business Central Job Queue.';
    /*
     * The v1 draft order endpoint, whose whole contract was the OMS PO reference: it keyed replay detection on
     * that number and refused a repeat carrying a different payload hash. Business Central owns document
     * identity now, OMS sends a hidden command id instead, and nothing has called this since that cutover.
     *
     * A page cannot carry ObsoleteState, so it is retired by closing it instead: insertion is refused and the
     * retired fields are gone from the layout, which leaves a readable object that can no longer create a
     * document or reach a field that no longer exists. Replay protection went with them — it keyed on the OMS
     * reference — and nothing is lost by that, because nothing can be inserted here at all.
     */

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(number; Rec."No.") { Caption = 'Number'; Editable = false; }
                field(vendorNumber; Rec."Vendor No.") { Caption = 'Vendor Number'; }
                field(currencyCode; Rec."OMS Currency Code") { Caption = 'Currency Code'; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code'; }
                field(expectedReceiptDate; Rec."Expected Receipt Date") { Caption = 'Expected Receipt Date'; }
                field(status; Rec.Status) { Caption = 'Status'; Editable = false; }
                field(lastErrorMessage; Rec."Last Error Message") { Caption = 'Last Error Message'; Editable = false; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; Editable = false; }
                part(draftOrderLines; "OMS2 Draft Order Lines API")
                {
                    Caption = 'Draft Order Lines';
                    EntityName = 'draftOrderLine';
                    EntitySetName = 'draftOrderLines';
                    SubPageLink = "Document No." = field("No.");
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
    end;
}
