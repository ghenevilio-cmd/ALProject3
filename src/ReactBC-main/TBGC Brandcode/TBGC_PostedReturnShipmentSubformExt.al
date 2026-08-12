pageextension 80281 "TBGC Posted Return Shpt" extends "Posted Return Shipment Subform"
{
    layout
    {
        addbefore(Description)
        {
            field("TBGC Brand Code"; Rec."TBGC Brand Code")
            {
                ApplicationArea = All;
            }
        }
    }
}
