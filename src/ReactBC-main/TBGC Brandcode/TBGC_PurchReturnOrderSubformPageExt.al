pageextension 80278 "TBGC Purch Return Order" extends "Purchase Return Order Subform"
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
