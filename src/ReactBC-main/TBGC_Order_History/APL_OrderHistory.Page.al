page 80298 "TBGC APL Order History"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "TBGC APL Order History";
    Caption = 'APL Order History';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Location Code", "History Created At", "History ID", "Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(HistoryLines)
            {
                field("History Created At"; Rec."History Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this order history entry was created.';
                }
                field("History ID"; Rec."History ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the history batch identifier.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the location for this order history.';
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the expected receipt date saved with the order history.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who created the order history.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor number saved in the order history.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number saved in the order history.';
                }
                field("Brand Code"; Rec."Brand Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the brand code saved in the order history.';
                }
                field("Brand Description"; Rec."Brand Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the brand description from the custom purchase price saved in the order history.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure saved in the order history.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity saved in the order history.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the direct unit cost saved in the order history.';
                }
            }
        }
    }
}
