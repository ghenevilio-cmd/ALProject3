page 80297 "Market List Access"
{
    PageType = List;
    SourceTable = "User Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Market List Access';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("TBGC Market List Permission"; Rec."TBGC Market List Permission")
                {
                    ApplicationArea = All;
                }
                field("TBGC APL Item Family"; Rec."TBGC APL Item Family")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which Item Family this user can manage in the Approved Product List. Set to ALL to allow all item families. Leave blank to block the user from adding or editing any items.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemFamily: Record "LSC Item Family";
                        ItemFamilyList: Page "LSC Item Families";
                    begin
                        ItemFamilyList.LookupMode(true);
                        if ItemFamilyList.RunModal() = Action::LookupOK then begin
                            ItemFamilyList.GetRecord(ItemFamily);
                            Rec.Validate("TBGC APL Item Family", ItemFamily.Code);
                            Text := ItemFamily.Code;
                        end;
                        exit(true);
                    end;
                }
            }
        }
    }
}
