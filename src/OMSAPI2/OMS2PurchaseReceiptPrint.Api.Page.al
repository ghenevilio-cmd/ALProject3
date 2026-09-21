page 80260 "OMS2 Receipt Print API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityName = 'printablePurchaseReceipt';
    EntitySetName = 'printablePurchaseReceipts';
    PageType = API;
    SourceTable = "Purch. Rcpt. Header";
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Receipts)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(number; Rec."No.") { Caption = 'Number'; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
        Rec.SetFilter("Order No.", '<>%1', '');
    end;

    [ServiceEnabled]
    procedure print(): Text
    var
        ReceiptHeader: Record "Purch. Rcpt. Header";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        RecRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
    begin
        Rec.TestField("No.");
        Rec.TestField("Order No.");
        ReceiptHeader := Rec;
        ReceiptHeader.SetRecFilter();
        RecRef.GetTable(ReceiptHeader);
        TempBlob.CreateOutStream(OutStr);
        // Standard posted Purchase - Receipt, report 408. Never render the purchase order here.
        Report.SaveAs(Report::"Purchase - Receipt", '', ReportFormat::Pdf, OutStr, RecRef);
        TempBlob.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr));
    end;
}

permissionsetextension 80260 "OMS2 Receipt Print Read" extends "OMS2 API READ"
{
    Permissions = page "OMS2 Receipt Print API" = X,
                  report "Purchase - Receipt" = X;
}

permissionsetextension 80261 "OMS2 Receipt Print Write" extends "OMS2 API WRITE"
{
    Permissions = page "OMS2 Receipt Print API" = X,
                  report "Purchase - Receipt" = X;
}
