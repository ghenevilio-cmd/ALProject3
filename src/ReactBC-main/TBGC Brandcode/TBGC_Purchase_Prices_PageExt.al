pageextension 80261 "TBGC Purchase Prices Ext" extends "Purchase Prices"
{
    layout
    {
        addafter("Ending Date")
        {
            field("TBGC Brand Code"; Rec."TBGC Brand Code")
            {
                ApplicationArea = All;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the custom Approved Product List.';
                ObsoleteTag = '1.0.0.4';
            }

            field("TBGC Brand Description"; Rec."TBGC Brand Description")
            {
                ApplicationArea = All;
                Editable = false;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the custom Approved Product List.';
                ObsoleteTag = '1.0.0.4';
            }

            field("TBGC Zoning Code"; Rec."TBGC Zoning Code")
            {
                ApplicationArea = All;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the custom Approved Product List.';
                ObsoleteTag = '1.0.0.4';
            }
            field("TBGC Concept Code"; Rec."TBGC Concept Code")
            {
                ApplicationArea = All;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the custom Approved Product List.';
                ObsoleteTag = '1.0.0.4';
            }
        }

        addbefore("Vendor No.")
        {
            field("Inactive"; Rec."Inactive")
            {
                ApplicationArea = All;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the custom Approved Product List.';
                ObsoleteTag = '1.0.0.4';
            }
        }
    }
}
