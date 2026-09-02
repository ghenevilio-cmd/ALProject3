page 80231 "OMS2 Purchase Orders API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Purchase Order';
    EntitySetCaption = 'OMS Purchase Orders';
    EntityName = 'purchaseOrder';
    EntitySetName = 'purchaseOrders';
    PageType = API;
    SourceTable = "Purchase Header";
    SourceTableView = where("Document Type" = const(Order));
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ChangeTrackingAllowed = true;
    Extensible = false;
    AboutText = 'Creates and releases standard Business Central purchase orders submitted by OMS.';

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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                    Editable = false;
                }
                field(omsPoReferenceNo; OmsPoReferenceNo)
                {
                    Caption = 'OMS PO Reference Number';
                }
                field(omsPayloadHash; OmsPayloadHash)
                {
                    Caption = 'OMS Payload Hash';
                }
                field(vendorNumber; VendorNumber)
                {
                    Caption = 'Vendor Number';
                }
                field(vendorName; Rec."Buy-from Vendor Name")
                {
                    Caption = 'Vendor Name';
                    Editable = false;
                }
                field(currencyCode; CurrencyCode)
                {
                    Caption = 'Currency Code';
                }
                field(locationCode; LocationCode)
                {
                    Caption = 'Location Code';
                }
                field(requestedReceiptDate; RequestedReceiptDate)
                {
                    Caption = 'Requested Receipt Date';
                }
                field(paymentTermsCode; PaymentTermsCode)
                {
                    Caption = 'Payment Terms Code';
                }
                field(shipmentMethodCode; ShipmentMethodCode)
                {
                    Caption = 'Shipment Method Code';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(purchaseOrderLines; "OMS2 Purchase Order Lines API")
                {
                    Caption = 'Purchase Order Lines';
                    EntityName = 'purchaseOrderLine';
                    EntitySetName = 'purchaseOrderLines';
                    SubPageLink = "Document Type" = const(Order), "Document No." = field("No.");
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OmsPoReferenceNo := Rec."OMS PO Ref. No.";
        OmsPayloadHash := Rec."OMS PO Payload Hash";
        VendorNumber := Rec."Buy-from Vendor No.";
        CurrencyCode := Rec."Currency Code";
        LocationCode := Rec."Location Code";
        RequestedReceiptDate := Rec."Expected Receipt Date";
        PaymentTermsCode := Rec."Payment Terms Code";
        ShipmentMethodCode := Rec."Shipment Method Code";
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ExistingPurchaseHeader: Record "Purchase Header";
        POValidationMgt: Codeunit "TBGC PO Validation Mgt";
    begin
        if OmsPoReferenceNo = '' then
            Error(OmsReferenceRequiredErr);
        if OmsPayloadHash = '' then
            Error(PayloadHashRequiredErr);

        ExistingPurchaseHeader.LockTable();
        ExistingPurchaseHeader.SetRange("Document Type", ExistingPurchaseHeader."Document Type"::Order);
        ExistingPurchaseHeader.SetRange("OMS PO Ref. No.", OmsPoReferenceNo);
        if ExistingPurchaseHeader.FindFirst() then begin
            if ExistingPurchaseHeader."OMS PO Payload Hash" <> OmsPayloadHash then
                Error(ChangedReplayErr, OmsPoReferenceNo);
            Rec := ExistingPurchaseHeader;
            exit(false);
        end;

        POValidationMgt.ValidateHeaderBeforeInsert(VendorNumber, LocationCode, RequestedReceiptDate);
        Rec."Document Type" := Rec."Document Type"::Order;
        Rec.Validate("OMS PO Ref. No.", OmsPoReferenceNo);
        Rec.Validate("OMS PO Payload Hash", OmsPayloadHash);
        Rec.Validate("Buy-from Vendor No.", VendorNumber);
        if CurrencyCode <> '' then
            Rec.Validate("Currency Code", CurrencyCode);
        Rec.Validate("Location Code", LocationCode);
        if Rec."Shortcut Dimension 1 Code" <> LocationCode then
            Rec.Validate("Shortcut Dimension 1 Code", LocationCode);
        Rec.Validate("Expected Receipt Date", RequestedReceiptDate);
        if PaymentTermsCode <> '' then
            Rec.Validate("Payment Terms Code", PaymentTermsCode);
        if ShipmentMethodCode <> '' then
            Rec.Validate("Shipment Method Code", ShipmentMethodCode);
        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(OmsPoReferenceNo);
        Clear(OmsPayloadHash);
        Clear(VendorNumber);
        Clear(CurrencyCode);
        Clear(LocationCode);
        Clear(RequestedReceiptDate);
        Clear(PaymentTermsCode);
        Clear(ShipmentMethodCode);
        Rec."Document Type" := Rec."Document Type"::Order;
    end;

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure Release(var ActionContext: WebServiceActionContext)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."No.");
        PurchaseHeader.TestField("OMS PO Ref. No.");
        PurchaseHeader.TestField("OMS PO Payload Hash");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.IsEmpty() then
            Error(NoLinesErr);

        if PurchaseHeader.Status = PurchaseHeader.Status::Open then
            ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader)
        else
            PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);

        Rec.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"OMS2 Purchase Orders API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    var
        OmsPoReferenceNo: Code[11];
        OmsPayloadHash: Code[64];
        VendorNumber: Code[20];
        CurrencyCode: Code[10];
        LocationCode: Code[20];
        RequestedReceiptDate: Date;
        PaymentTermsCode: Code[10];
        ShipmentMethodCode: Code[10];
        OmsReferenceRequiredErr: Label 'OMS PO Reference Number is required.';
        PayloadHashRequiredErr: Label 'OMS Payload Hash is required.';
        NoLinesErr: Label 'The purchase order must contain at least one line before release.';
        ChangedReplayErr: Label 'OMS PO reference %1 was already used with a different payload.';
}
