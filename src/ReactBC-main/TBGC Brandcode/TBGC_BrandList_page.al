page 80265 "TBGC Brand List"
{
    PageType = List;
    SourceTable = "TBGC Brand List";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'TBGC Brand List';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }

                field("TBGC Brand Code"; Rec."TBGC Brand Code")
                {
                    ApplicationArea = All;
                }

                field("TBGC Brand Description"; Rec."TBGC Brand Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
