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
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ChangeTrackingAllowed = true;
    Extensible = false;
    AboutText = 'Creates idempotent TBGC Draft Orders for conversion by the standard Business Central Job Queue.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(number; Rec."No.") { Caption = 'Number'; Editable = false; }
                field(omsPoReferenceNo; Rec."OMS PO Ref. No.") { Caption = 'OMS PO Reference Number'; }
                field(omsPayloadHash; Rec."OMS PO Payload Hash") { Caption = 'OMS Payload Hash'; }
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Existing: Record "TBGC Draft Order Header";
        POValidationMgt: Codeunit "TBGC PO Validation Mgt";
    begin
        Rec.TestField("OMS PO Ref. No.");
        Rec.TestField("OMS PO Payload Hash");
        Rec.TestField("Vendor No.");
        Rec.TestField("OMS Currency Code");
        Rec.TestField("Location Code");
        Rec.TestField("Expected Receipt Date");

        Existing.LockTable();
        Existing.SetRange("OMS PO Ref. No.", Rec."OMS PO Ref. No.");
        if Existing.FindFirst() then begin
            if Existing."OMS PO Payload Hash" <> Rec."OMS PO Payload Hash" then
                Error('OMS PO reference %1 was already used with a different payload.', Rec."OMS PO Ref. No.");
            Rec := Existing;
            exit(false);
        end;

        POValidationMgt.ValidateHeaderBeforeInsert(
          Rec."Vendor No.", Rec."Location Code", Rec."Expected Receipt Date");
        Rec.Type := Rec.Type::Checkout;
        Rec.Validate("Released Date", Today);
        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Type := Rec.Type::Checkout;
        Rec.Status := Rec.Status::Open;
    end;

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
    end;
}
