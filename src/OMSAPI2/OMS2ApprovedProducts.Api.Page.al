page 80244 "OMS2 Approved Products API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityName = 'approvedProduct';
    EntitySetName = 'approvedProducts';
    EntityCaption = 'OMS Approved Product';
    EntitySetCaption = 'OMS Approved Products';
    PageType = API;
    SourceTable = "Approved Product List";
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
            repeater(Group)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(entryNumber; Rec."Entry No.") { Caption = 'Entry Number'; }
                field(vendorNumber; Rec."Vendor No.") { Caption = 'Vendor Number'; }
                field(vendorName; Rec."Vendor Name") { Caption = 'Vendor Name'; }
                field(itemNumber; Rec."Item No.") { Caption = 'Item Number'; }
                field(itemDescription; ItemDescription) { Caption = 'Item Description'; }
                /// Blank means the item belongs to no family: OMS neither orders nor receives it until one is set.
                field(itemFamilyCode; ItemFamilyCode) { Caption = 'Item Family Code'; }
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { Caption = 'Unit of Measure Code'; }
                field(directUnitCost; Rec."Direct Unit Cost") { Caption = 'Direct Unit Cost'; }
                field(minimumQuantity; Rec."Minimum Quantity") { Caption = 'Minimum Quantity'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'Currency Code'; }
                field(brandCode; Rec."TBGC Brand Code") { Caption = 'Brand Code'; }
                field(brandDescription; Rec."TBGC Brand Description") { Caption = 'Brand Description'; }
                field(conceptCode; Rec."TBGC Concept Code") { Caption = 'Concept Code'; }
                field(zoningCode; Rec."TBGC Zoning Code") { Caption = 'Zoning Code'; }
                field(city; Rec."TBGC City") { Caption = 'City'; }
                field(startingDate; Rec."Starting Date") { Caption = 'Starting Date'; }
                field(endingDate; Rec."Ending Date") { Caption = 'Ending Date'; }
                field(inactive; Rec.Inactive) { Caption = 'Inactive'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        Clear(ItemDescription);
        Clear(ItemFamilyCode);
        Item.SetLoadFields(Description, "LSC Item Family Code");
        if Item.Get(Rec."Item No.") then begin
            ItemDescription := Item.Description;
            ItemFamilyCode := Item."LSC Item Family Code";
        end;
    end;

    var
        ItemDescription: Text[100];
        ItemFamilyCode: Code[10];
}
