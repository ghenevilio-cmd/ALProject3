report 80300 "APL Per Concept"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = APLPerConcept;

    dataset
    {
        dataitem("Approved Product List"; "Approved Product List")
        {
            RequestFilterFields = "Item Family Code";

            column(Inactive; "Inactive")
            {
            }

            column(Vendor_No_; "Vendor No.")
            {
            }

            column(Vendor_Name; "Vendor Name")
            {
            }
            column(TBGC_Concept_Code; "TBGC Concept Code")
            {
            }

            column(Item_Family_Code; "Item Family Code")
            {
            }

            column(Item_No; "Item No.")
            {
            }

            column(TBGC_Brand_Code; "TBGC Brand Code")
            {
            }

            column(TBGC_Brand_Description; "TBGC Brand Description")
            {
            }

            column(TBGC_Zoning_Code; "TBGC Zoning Code")
            {
            }

            column(Direct_Unit_Cost; "Direct Unit Cost")
            {
                AutoFormatType = 10;
                AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
                DecimalPlaces = 2 : 2;
            }

            column(Unit_of_Measure_Code; "Unit of Measure Code")
            {
            }

            trigger OnPreDataItem()
            begin
                SetRange("Inactive", false);
                if not ApplyConceptFilter() then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(TBGCConceptCodeFilter; TBGCConceptCodeFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'TBGC Concept Code';
                        ToolTip = 'Specifies the TBGC Concept Code assigned to the current user.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            TBGCConcept: Record "TBGC Concept Table";
                        begin
                            TBGCConcept.SetRange("Template Master", UserId());

                            if Page.RunModal(Page::"TBGC Concept List", TBGCConcept) = Action::LookupOK then begin
                                Text := TBGCConcept."Concept Code";
                                TBGCConceptCodeFilter := TBGCConcept."Concept Code";
                            end;

                            exit(true);
                        end;

                        trigger OnValidate()
                        var
                            TBGCConcept: Record "TBGC Concept Table";
                        begin
                            if TBGCConceptCodeFilter = '' then
                                exit;

                            TBGCConcept.SetRange("Template Master", UserId());
                            TBGCConcept.SetRange("Concept Code", TBGCConceptCodeFilter);
                            if TBGCConcept.IsEmpty() then
                                Error(ConceptNotAssignedErr, TBGCConceptCodeFilter);
                        end;
                    }
                }
            }
        }
    }

    rendering
    {
        layout(APLPerConcept)
        {
            Type = Excel;
            LayoutFile = 'src\APL Request Page\reportlayout\APLPerConcept.xlsx';
        }
    }

    var
        TBGCConceptCodeFilter: Code[20];
        ConceptNotAssignedErr: Label 'Concept %1 is not assigned to your user account.';

    local procedure ApplyConceptFilter(): Boolean
    var
        TBGCConcept: Record "TBGC Concept Table";
        AssignedConceptFilter: Text;
    begin
        if TBGCConceptCodeFilter <> '' then begin
            "Approved Product List".SetRange("TBGC Concept Code", TBGCConceptCodeFilter);
            exit(true);
        end;

        TBGCConcept.SetRange("Template Master", UserId());
        if TBGCConcept.FindSet() then
            repeat
                if AssignedConceptFilter <> '' then
                    AssignedConceptFilter += '|';

                AssignedConceptFilter += TBGCConcept."Concept Code";
            until TBGCConcept.Next() = 0;

        if AssignedConceptFilter = '' then
            exit(false);

        "Approved Product List".SetFilter("TBGC Concept Code", AssignedConceptFilter);
        exit(true);
    end;
}
