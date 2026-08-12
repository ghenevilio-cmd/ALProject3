codeunit 80291  "TBGC Draft Conversion Context"
{
    SingleInstance = true;

    var
        ActiveDocumentNo: Code[20];
        ActiveLocationCode: Code[20];

    procedure BeginForDocument(DocumentNo: Code[20]; LocationCode: Code[20])
    begin
        ActiveDocumentNo := DocumentNo;
        ActiveLocationCode := LocationCode;
    end;

    procedure EndForDocument(DocumentNo: Code[20])
    begin
        if ActiveDocumentNo <> DocumentNo then
            exit;

        Clear(ActiveDocumentNo);
        Clear(ActiveLocationCode);
    end;

    procedure TryGetLocation(DocumentNo: Code[20]; var LocationCode: Code[20]): Boolean
    begin
        if (DocumentNo = '') or (ActiveDocumentNo = '') then
            exit(false);

        if ActiveDocumentNo <> DocumentNo then
            exit(false);

        if ActiveLocationCode = '' then
            exit(false);

        LocationCode := ActiveLocationCode;
        exit(true);
    end;
}
