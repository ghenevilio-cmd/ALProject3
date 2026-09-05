page 80246 "OMS2 Receivable PO Lines API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Receivable Purchase Order Line';
    EntitySetCaption = 'OMS Receivable Purchase Order Lines';
    EntityName = 'receivablePurchaseOrderLine';
    EntitySetName = 'receivablePurchaseOrderLines';
    PageType = API;
    SourceTable = "Purchase Line";
    SourceTableView = where("Document Type" = const(Order), Type = const(Item));
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;
    AboutText = 'Reads the ordered, received and still outstanding quantity of each OMS purchase order line.';

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
                field(documentNumber; Rec."Document No.")
                {
                    Caption = 'Document Number';
                }
                field(lineNumber; Rec."Line No.")
                {
                    Caption = 'Line Number';
                }
                field(itemNumber; Rec."No.")
                {
                    Caption = 'Item Number';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(brandCode; Rec."TBGC Brand Code")
                {
                    Caption = 'Brand Code';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                // What has already been received, and what the receiver may still count in. Business Central
                // keeps both on the line, so OMS never has to add receipts up for itself.
                field(quantityReceived; Rec."Quantity Received")
                {
                    Caption = 'Quantity Received';
                }
                field(outstandingQuantity; Rec."Outstanding Quantity")
                {
                    Caption = 'Outstanding Quantity';
                }
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Line Amount';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
    end;
}
