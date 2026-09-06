page 80248 "OMS2 Draft Order Lines API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Draft Order Line';
    EntitySetCaption = 'OMS Draft Order Lines';
    EntityName = 'draftOrderLine';
    EntitySetName = 'draftOrderLines';
    PageType = API;
    SourceTable = "TBGC Draft Order Line";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(documentNumber; Rec."Document No.") { Caption = 'Document Number'; Editable = false; }
                field(lineNumber; Rec."Line No.") { Caption = 'Line Number'; }
                field(itemNumber; Rec."Item No.") { Caption = 'Item Number'; }
                field(brandCode; Rec."TBGC Brand Code") { Caption = 'Brand Code'; }
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { Caption = 'Unit of Measure Code'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(directUnitCost; Rec."Direct Unit Cost") { Caption = 'Direct Unit Cost'; }
                field(description; Rec.Description) { Caption = 'Description'; Editable = false; }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Header: Record "TBGC Draft Order Header";
        Existing: Record "TBGC Draft Order Line";
        Item: Record Item;
    begin
        Header.Get(Rec."Document No.");
        Header.TestField(Status, Header.Status::Open);
        Rec.TestField("Line No.");
        Rec.TestField("Item No.");
        Rec.TestField("Unit of Measure Code");
        if Rec.Quantity <= 0 then
            Error('Quantity must be greater than zero.');
        if Rec."Direct Unit Cost" < 0 then
            Error('Direct Unit Cost cannot be negative.');

        if Existing.Get(Rec."Document No.", Rec."Line No.") then begin
            if (Existing."Item No." <> Rec."Item No.") or
               (Existing."TBGC Brand Code" <> Rec."TBGC Brand Code") or
               (Existing."Unit of Measure Code" <> Rec."Unit of Measure Code") or
               (Existing.Quantity <> Rec.Quantity) or
               (Existing."Direct Unit Cost" <> Rec."Direct Unit Cost")
            then
                Error('Draft order line %1 was already used with different values.', Rec."Line No.");
            Rec := Existing;
            exit(false);
        end;

        Item.Get(Rec."Item No.");
        Item.TestField(Blocked, false);
        Rec."Vendor No." := Header."Vendor No.";
        Rec.Description := CopyStr(Item.Description, 1, MaxStrLen(Rec.Description));
        exit(true);
    end;
}
