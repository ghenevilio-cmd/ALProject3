pageextension 80275 "TBGC Purch Invoice Subf" extends "Purch. Invoice Subform"
{
    layout
    {
        addbefore(Description)
        {
            field("TBGC Brand Code"; Rec."TBGC Brand Code")
            {
                ApplicationArea = All;

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
