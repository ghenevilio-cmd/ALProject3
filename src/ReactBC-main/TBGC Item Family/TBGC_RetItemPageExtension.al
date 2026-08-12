pageextension 80210 "Item Families Ext" extends "LSC Retail Item List"
{
    layout
    {
        addafter("Base Unit of Measure")
        {
            field("Item Family"; Rec."LSC Item Family Code")
            {
                ApplicationArea = All;
                Editable = false;
                visible = true;
            }
        }
    }
}