page 80206 "TBGC Concept List"
{
    PageType = List;
    SourceTable = "TBGC Concept Table";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'TBGC Concept';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Concept Code"; Rec."Concept Code")
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field("Template Master"; Rec."Template Master")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Store List")
            {
                ApplicationArea = All;
                Caption = 'Store List';
                Image = List;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Store: Record "LSC Store";
                begin
                    if Rec."Concept Code" = '' then
                        Error('Please select a concept code first.');

                    Store.Reset();
                    Store.SetRange("TBGC Concept Code", Rec."Concept Code");

                    Page.RunModal(Page::"TBGC Concept Store List", Store);
                end;
            }
        }
    }
}
