pageextension 80266 "TBGC Item Card Ext" extends "Item Card"
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

    actions
    {
        addlast(Processing)
        {
            action("TBGC Brand List")
            {
                ApplicationArea = All;
                Caption = 'TBGC Brand List';
                Image = List;
                RunObject = page "TBGC Brand List";
                RunPageLink = "Item No." = field("No.");
            }
        }
    }
}
