pageextension 80283 "TBGC Item List Ext" extends "Item List"
{
    layout
    {
        addafter(Description)
        {
            field("TBGC Brand Code"; Rec."TBGC Brand Code")
            {
                ApplicationArea = All;
            }
        }
    }
}
