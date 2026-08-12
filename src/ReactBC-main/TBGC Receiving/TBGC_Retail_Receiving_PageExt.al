pageextension 80211 "RR System Created At" extends "LSC Retail Receiving List"
{
    layout
    {
        addafter("Location Code")
        {
            field("TBGC Original Created By"; Rec."TBGC Original Created By")
            {
                ApplicationArea = All;
                Caption = 'Original CREATED BY';
                Editable = false;
            }
            field("TBGC Order Date"; Rec."TBGC Order Date")
            {
                ApplicationArea = All;
                Caption = 'Order Date';
                Editable = false;
            }
            field("System Created At"; Rec."SystemCreatedAt")
            {
                ApplicationArea = All;
                Caption = 'System Created At';
                Editable = false;
            }
        }
    }
}
