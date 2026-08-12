codeunit 80299 "TBGC Purchase Release Track"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReleasePurchaseDoc', '', false, false)]
    local procedure ReleasePurchaseDocumentOnAfterReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var LinesWereModified: Boolean; SkipWhseRequestOperations: Boolean)
    var
        ReleaseDateTime: DateTime;
    begin
        if PreviewMode then
            exit;

        ReleaseDateTime := CurrentDateTime();

        if GetTBGReleasedDateTime(PurchaseHeader) <> 0DT then
            exit;

        SetTBGReleasedDateTime(PurchaseHeader, ReleaseDateTime);
        PurchaseHeader.Modify(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReopenPurchaseDoc', '', false, false)]
    local procedure ReleasePurchaseDocumentOnAfterReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; SkipWhseRequestOperations: Boolean)
    begin
        if PreviewMode then
            exit;
 
        if GetTBGReleasedDateTime(PurchaseHeader) = 0DT then
            exit;

        ClearTBGReleasedFields(PurchaseHeader);
        PurchaseHeader.Modify(false);
    end;

    local procedure GetTBGReleasedDateTime(PurchaseHeader: Record "Purchase Header"): DateTime
    var
        PurchHeaderRef: RecordRef;
        FieldRef: FieldRef;
    begin
        PurchHeaderRef.GetTable(PurchaseHeader);

        if PurchHeaderRef.FieldExist(60211) then begin
            FieldRef := PurchHeaderRef.Field(60211);
            exit(FieldRef.Value);
        end;

        exit(0DT);
    end;

    local procedure SetTBGReleasedDateTime(var PurchaseHeader: Record "Purchase Header"; ReleaseDateTime: DateTime)
    var
        PurchHeaderRef: RecordRef;
        FieldRef: FieldRef;
    begin
        PurchHeaderRef.GetTable(PurchaseHeader);

        if PurchHeaderRef.FieldExist(60211) then begin
            FieldRef := PurchHeaderRef.Field(60211);
            FieldRef.Value := ReleaseDateTime;
        end;

        PurchHeaderRef.SetTable(PurchaseHeader);
    end;

    local procedure ClearTBGReleasedFields(var PurchaseHeader: Record "Purchase Header")
    var
        PurchHeaderRef: RecordRef;
        FieldRef: FieldRef;
    begin
        PurchHeaderRef.GetTable(PurchaseHeader);

        if PurchHeaderRef.FieldExist(60211) then begin
            FieldRef := PurchHeaderRef.Field(60211);
            FieldRef.Value := 0DT;
        end;

        PurchHeaderRef.SetTable(PurchaseHeader);
    end;
}
