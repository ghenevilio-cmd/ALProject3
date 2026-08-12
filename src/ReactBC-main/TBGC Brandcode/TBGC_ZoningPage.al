page 80202 "TBGC Zoning List"
{
    PageType = List;
    SourceTable = "TBGC Zoning Table";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'TBGC Zoning';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Zoning Code"; Rec."Zoning Code")
                {
                    ApplicationArea = All;
                }

                field("Description"; Rec."Description")
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
                    if Rec."Zoning Code" = '' then
                        Error('Please select a zoning code first.');

                    Store.Reset();
                    Store.SetRange("TBGC Zoning Code", Rec."Zoning Code");

                    Page.RunModal(Page::"TBGC Zoned Store List", Store);
                end;
            }
        }
    }
}