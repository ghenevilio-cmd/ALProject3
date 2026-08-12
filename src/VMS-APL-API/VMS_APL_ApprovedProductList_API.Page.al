page 80222 "VMS APL Approved Prod. API"
{
    APIVersion = 'v2.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'vmsaplapi';

    EntityCaption = 'Approved Product List';
    EntitySetCaption = 'Approved Product Lists';
    EntityName = 'approvedProductList';
    EntitySetName = 'approvedProductLists';

    PageType = API;
    SourceTable = "Approved Product List";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;

    AboutText = 'Read-only API endpoint for pulling Approved Product List records.';
    Extensible = false;

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
                field(Inactive; Rec.Inactive)
                {
                    Caption = 'Inactive';
                    Editable = false;
                }
                field(entryNumber; Rec."Entry No.")
                {
                    Caption = 'Entry Number';
                    Editable = false;
                }
                field(vendorNumber; Rec."Vendor No.")
                {
                    Caption = 'Vendor Number';
                    Editable = true;
                }
                field(vendorName; Rec."Vendor Name")
                {
                    Caption = 'Vendor Name';
                    Editable = false;
                }
                field(itemNumber; Rec."Item No.")
                {
                    Caption = 'Item Number';
                    Editable = true;
                }
                field(itemFamilyCode; Rec."Item Family Code")
                {
                    Caption = 'Item Family Code';
                    Editable = true;
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                    Editable = true;
                }
                field(minimumQuantity; Rec."Minimum Quantity")
                {
                    Caption = 'Minimum Quantity';
                    Editable = true;
                }
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                    Editable = true;
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                    Editable = true;
                }
                field(endingDate; Rec."Ending Date")
                {
                    Caption = 'Ending Date';
                    Editable = true;
                }
                field(tbgcBrandCode; Rec."TBGC Brand Code")
                {
                    Caption = 'TBGC Brand Code';
                    Editable = true;
                }
                field(tbgcBrandDescription; Rec."TBGC Brand Description")
                {
                    Caption = 'TBGC Brand Description';
                    Editable = false;
                }
                field(tbgcZoningCode; Rec."TBGC Zoning Code")
                {
                    Caption = 'TBGC Zoning Code';
                    Editable = true;
                }
                field(tbgcConceptCode; Rec."TBGC Concept Code")
                {
                    Caption = 'TBGC Concept Code';
                    Editable = true;
                }
                field(tbgcCity; Rec."TBGC City")
                {
                    Caption = 'TBGC City';
                    Editable = true;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                field(approvedBy; Rec."Approved By:")
                {
                    Caption = 'Approved By';
                    Editable = true;
                }
            }
        }
    }
}

