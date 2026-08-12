tableextension 80295 "TBGC User Setup Market List" extends "User Setup"
{
    fields
    {
        field(80295; "TBGC Market List Permission"; Option)
        {
            Caption = 'Permission';
            DataClassification = CustomerContent;
            OptionMembers = "NOT ALLOWED",ALLOWED;
        }
        field(80296; "TBGC ML Del Edit"; Boolean)
        {
            Caption = 'Draft Ord. Del/Edit';
            DataClassification = CustomerContent;
        }
        field(80297; "TBGC APL Item Family"; Code[20])
        {
            Caption = 'Allowed Item Family';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ItemFamily: Record "LSC Item Family";
            begin
                "TBGC APL Item Family" := UpperCase("TBGC APL Item Family");

                // Blank = blocked, ALL = unrestricted — both are valid, no lookup needed
                if ("TBGC APL Item Family" = '') or ("TBGC APL Item Family" = 'ALL') then
                    exit;

                // Otherwise validate against LSC Item Family
                if not ItemFamily.Get("TBGC APL Item Family") then
                    Error('Item Family Code ''%1'' does not exist. Enter a valid Item Family Code or ALL.', "TBGC APL Item Family");
            end;
        }
    }
}
