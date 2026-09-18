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
                field(draftOrderNumber; Rec."TBGC Draft Order No.")
                {
                    Caption = 'Draft Order Number';
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

    /// <summary>
    /// Bound action: POST .../receivablePurchaseOrders({id})/Microsoft.NAV.print
    ///
    /// Renders this one purchase order with the report Report Selections holds for P.Order — the same report
    /// the order card's own Print action runs, which here is report 405 "Order" with the TBGPurchaseOrder
    /// layout and the QR code reportextension 80201 adds. OMS shows that document rather than drawing a second
    /// one of its own, so paper from OMS and paper from Business Central are the same paper.
    ///
    /// The PDF comes back as base64 text because an OData action returns JSON.
    /// </summary>
    [ServiceEnabled]
    procedure print(): Text
    var
        ReportSelections: Record "Report Selections";
        PurchaseHeader: Record "Purchase Header";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        RecRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
        NoReportErr: Label 'No report is set up for purchase orders in Report Selections.';
    begin
        PurchaseHeader := Rec;
        PurchaseHeader.SetRecFilter();
        RecRef.GetTable(PurchaseHeader);

        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Order");
        ReportSelections.SetFilter("Report ID", '<>0');
        if not ReportSelections.FindFirst() then
            Error(NoReportErr);

        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(ReportSelections."Report ID", '', ReportFormat::Pdf, OutStr, RecRef);
        TempBlob.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr));
    end;
}
