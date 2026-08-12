page 80268 "TBGC Brands"
{
    PageType = List;
    SourceTable = "TBGC Brands";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'TBGC Brands';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
