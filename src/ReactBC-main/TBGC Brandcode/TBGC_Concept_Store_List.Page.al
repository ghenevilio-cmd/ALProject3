page 80207 "TBGC Concept Store List"
{
    PageType = List;
    SourceTable = "LSC Store";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Stores by Concept';
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

                field("TBGC Concept Code"; Rec."TBGC Concept Code")
                {
                    ApplicationArea = All;
                    Caption = 'Concept Code';
                }
            }
        }
    }
}
