page 80220 "TBGC ML Ordering Day Setup"
{
    PageType = Card;
    SourceTable = "TBGC ML Ordering Day Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'ML Ordering Day Setup';
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Checkout Ordering Days';

                field("Allow Monday"; Rec."Allow Monday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Market List ordering is allowed on Monday.';
                }
                field("Allow Tuesday"; Rec."Allow Tuesday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Market List ordering is allowed on Tuesday.';
                }
                field("Allow Wednesday"; Rec."Allow Wednesday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Market List ordering is allowed on Wednesday.';
                }
                field("Allow Thursday"; Rec."Allow Thursday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Market List ordering is allowed on Thursday.';
                }
                field("Allow Friday"; Rec."Allow Friday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Market List ordering is allowed on Friday.';
                }
                field("Allow Saturday"; Rec."Allow Saturday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Market List ordering is allowed on Saturday.';
                }
                field("Allow Sunday"; Rec."Allow Sunday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Market List ordering is allowed on Sunday.';
                }
                field("Allow From Time"; Rec."Allow From Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the earliest time of day that checkout is allowed. Leave blank for no time restriction.';
                }
                field("Allow To Time"; Rec."Allow To Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the latest time of day that checkout is allowed. Leave blank for no time restriction.';
                }
            }
            group(Draft)
            {
                Caption = 'Draft Ordering Days';

                field("Draft Allow Monday"; Rec."Draft Allow Monday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether adding to a Market List draft is allowed on Monday.';
                }
                field("Draft Allow Tuesday"; Rec."Draft Allow Tuesday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether adding to a Market List draft is allowed on Tuesday.';
                }
                field("Draft Allow Wednesday"; Rec."Draft Allow Wednesday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether adding to a Market List draft is allowed on Wednesday.';
                }
                field("Draft Allow Thursday"; Rec."Draft Allow Thursday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether adding to a Market List draft is allowed on Thursday.';
                }
                field("Draft Allow Friday"; Rec."Draft Allow Friday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether adding to a Market List draft is allowed on Friday.';
                }
                field("Draft Allow Saturday"; Rec."Draft Allow Saturday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether adding to a Market List draft is allowed on Saturday.';
                }
                field("Draft Allow Sunday"; Rec."Draft Allow Sunday")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether adding to a Market List draft is allowed on Sunday.';
                }
                field("Draft Allow From Time"; Rec."Draft Allow From Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the earliest time of day that adding to a draft is allowed. Leave blank for no time restriction.';
                }
                field("Draft Allow To Time"; Rec."Draft Allow To Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the latest time of day that adding to a draft is allowed. Leave blank for no time restriction.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        EnsureSetupRecord();
    end;

    local procedure EnsureSetupRecord()
    begin
        if Rec.Get('DEFAULT') then
            exit;

        Rec.Init();
        Rec."Primary Key" := 'DEFAULT';
        Rec.Insert(true);
        Rec.Get('DEFAULT');
    end;
}
