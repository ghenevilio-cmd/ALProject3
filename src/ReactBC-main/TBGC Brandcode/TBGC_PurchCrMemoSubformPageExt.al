pageextension 80279 "TBGC Purch Cr Memo Subf" extends "Purch. Cr. Memo Subform"
{
    layout
    {
        addbefore(Description)
        {
            field("TBGC Brand Code"; Rec."TBGC Brand Code")
            {
                ApplicationArea = All;
                TableRelation = "TBGC Brand List"."TBGC Brand Code" WHERE("Item No." = FIELD("No."));

                trigger OnLookup(var Text: Text): Boolean
                var
                    BrandSelectionMgt: Codeunit "TBGC Brand Selection Mgt";
                begin
                    if BrandSelectionMgt.LookupPurchaseLineBrand(Rec) then begin
                        CurrPage.Update(false);
                        exit(true);
                    end;

                    exit(false);
                end;
            }
        }
    }
}
