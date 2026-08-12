page 80293 "TBGC Filtered Brand Lookup"
{
    PageType = List;
    SourceTable = "Approved Product List";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Available Brand Codes';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Brands)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }

                field("TBGC Brand Code"; Rec."TBGC Brand Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("TBGC Brand Description"; Rec."TBGC Brand Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    procedure SetFilters(ItemNo: Code[20]; VendorNo: Code[20]; ZoningCode: Code[20]; ConceptCode: Code[20])
    begin
        Rec.Reset();
        Rec.SetRange(Inactive, false);
        Rec.SetRange("Item No.", ItemNo);
        Rec.SetRange("Vendor No.", VendorNo);
        Rec.SetFilter("TBGC Brand Code", '<>%1', '');

        if ZoningCode <> '' then
            Rec.SetRange("TBGC Zoning Code", ZoningCode);

        if ConceptCode <> '' then
            Rec.SetRange("TBGC Concept Code", ConceptCode);
    end;
}
