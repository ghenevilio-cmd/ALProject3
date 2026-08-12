page 80267 "Approved Product List"
{
    PageType = List;
    SourceTable = "Approved Product List";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Approved Product List';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = true;
                }
                field(Inactive; Rec.Inactive)
                {
                    ApplicationArea = All;
                    Editable = IsInactiveToggleEditable;

                    trigger OnValidate()
                    begin
                        UpdateRecordEditability();
                        CurrPage.SaveRecord();
                        CurrPage.Update(false);
                    end;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }

                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }

                field("Item Family Code"; Rec."Item Family Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }

                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }

                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }

                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }

                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }

                field("TBGC Brand Code"; Rec."TBGC Brand Code")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }

                field("TBGC Brand Description"; Rec."TBGC Brand Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("TBGC Zoning Code"; Rec."TBGC Zoning Code")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }
                field("TBGC City"; Rec."TBGC City")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                    ToolTip = 'Specifies the city that this price applies to. Use ALL to make the price available to all cities under the same zoning/concept.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SelectedCity: Text;
                    begin
                        if not IsCurrentRecordEditable then
                            exit(true);

                        if not LookupCity(SelectedCity) then
                            exit(true);

                        Text := SelectedCity;
                        Rec.Validate("TBGC City", CopyStr(SelectedCity, 1, MaxStrLen(Rec."TBGC City")));
                        CurrPage.SaveRecord();
                        CurrPage.Update(false);
                        exit(true);
                    end;
                }
                field("TBGC Concept Code"; Rec."TBGC Concept Code")
                {
                    ApplicationArea = All;
                    Editable = IsCurrentRecordEditable;
                }

                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Modified By"; ModifiedByUserName)
                {
                    ApplicationArea = All;
                    Caption = 'Modified By';
                    Editable = false;
                    ToolTip = 'Specifies the user who last modified this record.';
                }
                field("Modified At"; Rec."SystemModifiedAt")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the date and time when this record was last modified.';
                }
                field("Approved By"; Rec."Approved By:")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the user who approved this record.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PreviewDraftPriceUpdates)
            {
                ApplicationArea = All;
                Caption = 'Preview Draft Price Updates';
                Image = Price;
                ToolTip = 'Preview open draft order lines where the latest Approved Product List price differs from the current draft price.';

                trigger OnAction()
                var
                    DraftPriceUpdates: Page "TBGC Draft Price Updates";
                begin
                    DraftPriceUpdates.LoadPreview();
                    DraftPriceUpdates.RunModal();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.GetFilter(Inactive) = '' then
            Rec.SetRange(Inactive, false);
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateRecordEditability();
        UpdateModifiedByUserName();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateRecordEditability();
        UpdateModifiedByUserName();
    end;

    var
        IsCurrentRecordEditable: Boolean;
        IsInactiveToggleEditable: Boolean;
        ModifiedByUserName: Text;

    local procedure UpdateModifiedByUserName()
    var
        UserRec: Record User;
    begin
        ModifiedByUserName := '';
        if IsNullGuid(Rec.SystemModifiedBy) then
            exit;

        if not UserRec.Get(Rec.SystemModifiedBy) then
            exit;

        if UserRec."Full Name" <> '' then
            ModifiedByUserName := UserRec."Full Name"
        else
            ModifiedByUserName := UserRec."User Name";
    end;

    local procedure LookupCity(var SelectedCity: Text): Boolean
    var
        Store: Record "LSC Store";
        SeenCities: Dictionary of [Text, Boolean];
        OptionsText: Text;
        SelectionIndex: Integer;
        CityOption: Text;
    begin
        AppendCityOption(OptionsText, 'ALL');
        SeenCities.Add('ALL', true);

        Store.Reset();
        if Rec."TBGC Zoning Code" <> '' then
            Store.SetRange("TBGC Zoning Code", Rec."TBGC Zoning Code");
        if Rec."TBGC Concept Code" <> '' then
            Store.SetRange("TBGC Concept Code", Rec."TBGC Concept Code");

        if Store.FindSet() then
            repeat
                if Store.City = '' then
                    continue;

                CityOption := UpperCase(Store.City);
                if SeenCities.ContainsKey(CityOption) then
                    continue;

                AppendCityOption(OptionsText, CityOption);
                SeenCities.Add(CityOption, true);
            until Store.Next() = 0;

        SelectionIndex := StrMenu(OptionsText, GetDefaultCitySelection(OptionsText), 'Select City');
        if SelectionIndex = 0 then
            exit(false);

        SelectedCity := SelectStr(SelectionIndex, OptionsText);
        exit(true);
    end;

    local procedure AppendCityOption(var OptionsText: Text; OptionValue: Text)
    begin
        if OptionsText = '' then
            OptionsText := OptionValue
        else
            OptionsText += ',' + OptionValue;
    end;

    local procedure GetDefaultCitySelection(OptionsText: Text): Integer
    var
        CurrentCity: Text;
        OptionIndex: Integer;
        OptionCount: Integer;
    begin
        CurrentCity := UpperCase(Rec."TBGC City");
        if CurrentCity = '' then
            CurrentCity := 'ALL';

        OptionCount := GetOptionCount(OptionsText);
        for OptionIndex := 1 to OptionCount do
            if SelectStr(OptionIndex, OptionsText) = CurrentCity then
                exit(OptionIndex);

        exit(1);
    end;

    local procedure GetOptionCount(OptionsText: Text): Integer
    begin
        if OptionsText = '' then
            exit(0);

        exit(StrLen(OptionsText) - StrLen(DelChr(OptionsText, '=', ',')) + 1);
    end;

    local procedure UpdateRecordEditability()
    begin
        IsCurrentRecordEditable := not Rec.Inactive;
        IsInactiveToggleEditable := IsCurrentRecordEditable or CurrentUserCanReactivate();
    end;

    local procedure CurrentUserCanReactivate(): Boolean
    var
        UserSetup: Record "User Setup";
    begin
        if not Rec.Inactive then
            exit(true);

        if not UserSetup.Get(CopyStr(UserId(), 1, 50)) then
            exit(false);

        exit(UserSetup."TBGC Allowed APL Activation");
    end;
}
