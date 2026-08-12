page 80203 "TBGC Zoned Store List"
{
    PageType = List;
    SourceTable = "LSC Store";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Stores by Zone';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }

                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }

                field("TBGC Zoning Code"; Rec."TBGC Zoning Code")
                {
                    ApplicationArea = All;
                    Caption = 'Zoning Code';
                }
                field("TBGC Concept Code"; Rec."TBGC Concept Code")
                {
                    ApplicationArea = All;
                    Caption = 'Concept Code';
                }
            }
        }
    }
}
