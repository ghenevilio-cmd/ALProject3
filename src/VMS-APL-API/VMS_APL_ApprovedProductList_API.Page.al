page 80222 "VMS APL Approved Prod. API"
{
    APIVersion = 'v2.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'vmsaplapi';

    EntityCaption = 'Approved Product List';
    EntitySetCaption = 'Approved Product Lists';
    EntityName = 'approvedProductList';
    EntitySetName = 'approvedProductLists';

    PageType = API;
    SourceTable = "Approved Product List";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;

    AboutText = 'Approved Product List read and conditional price-write API with protected employee attribution.';
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(Inactive; Rec.Inactive)
                {
                    Caption = 'Inactive';
                    Editable = false;
                }
                field(entryNumber; Rec."Entry No.")
                {
                    Caption = 'Entry Number';
                    Editable = false;
                }
                field(vendorNumber; Rec."Vendor No.")
                {
                    Caption = 'Vendor Number';
                    Editable = true;
                }
                field(vendorName; Rec."Vendor Name")
                {
                    Caption = 'Vendor Name';
                    Editable = false;
                }
                field(itemNumber; Rec."Item No.")
                {
                    Caption = 'Item Number';
                    Editable = true;
                }
                field(itemFamilyCode; Rec."Item Family Code")
                {
                    Caption = 'Item Family Code';
                    Editable = true;
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                    Editable = true;
                }
                field(minimumQuantity; Rec."Minimum Quantity")
                {
                    Caption = 'Minimum Quantity';
                    Editable = true;
                }
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                    Editable = true;
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                    Editable = true;
                }
                field(endingDate; Rec."Ending Date")
                {
                    Caption = 'Ending Date';
                    Editable = true;
                }
                field(tbgcBrandCode; Rec."TBGC Brand Code")
                {
                    Caption = 'TBGC Brand Code';
                    Editable = true;
                }
                field(tbgcBrandDescription; Rec."TBGC Brand Description")
                {
                    Caption = 'TBGC Brand Description';
                    Editable = false;
                }
                field(tbgcZoningCode; Rec."TBGC Zoning Code")
                {
                    Caption = 'TBGC Zoning Code';
                    Editable = true;
                }
                field(tbgcConceptCode; Rec."TBGC Concept Code")
                {
                    Caption = 'TBGC Concept Code';
                    Editable = true;
                }
                field(tbgcCity; Rec."TBGC City")
                {
                    Caption = 'TBGC City';
                    Editable = true;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                field(approvedBy; Rec."Approved By:")
                {
                    Caption = 'Approved By';
                    Editable = true;
                }
                field(attributionContractVersion; AttributionContractVersion) { Editable = false; }
                field(modifiedByStaffId; ModifiedByStaffId)
                {
                    trigger OnValidate()
                    begin
                        StaffSupplied := true;
                    end;
                }
                field(modifiedByEmployeeId; ModifiedByEmployeeId)
                {
                    trigger OnValidate()
                    begin
                        EmployeeIdSupplied := true;
                    end;
                }
                field(modifiedByEmployeeName; ModifiedByEmployeeName)
                {
                    trigger OnValidate()
                    begin
                        EmployeeNameSupplied := true;
                    end;
                }
                field(modificationCommandId; ModificationCommandId)
                {
                    trigger OnValidate()
                    begin
                        CommandSupplied := true;
                    end;
                }
                field(attributionSource; Rec."VMS Attribution Source") { Editable = false; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        AttributionContractVersion := AttributionGuard.ContractVersion();
    end;

    trigger OnAfterGetRecord()
    begin
        ModifiedByStaffId := Rec."VMS Staff ID";
        ModifiedByEmployeeId := Rec."VMS Employee ID";
        ModifiedByEmployeeName := Rec."VMS Employee Name";
        ModificationCommandId := Rec."VMS Command ID";
        ResetSupplied();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ModifiedByStaffId);
        Clear(ModifiedByEmployeeId);
        Clear(ModifiedByEmployeeName);
        Clear(ModificationCommandId);
        ResetSupplied();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not HasAttribution() then
            exit(true);
        WriteAttributed(true);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if not HasAttribution() then
            exit(true);
        WriteAttributed(false);
        exit(false);
    end;

    var
        AttributionGuard: Codeunit "VMS APL Attribution Guard";
        AttributionContractVersion: Integer;
        ModifiedByStaffId: Integer;
        ModifiedByEmployeeId: Text;
        ModifiedByEmployeeName: Text;
        ModificationCommandId: Guid;
        StaffSupplied: Boolean;
        EmployeeIdSupplied: Boolean;
        EmployeeNameSupplied: Boolean;
        CommandSupplied: Boolean;

    local procedure HasAttribution(): Boolean
    begin
        if not (StaffSupplied or EmployeeIdSupplied or EmployeeNameSupplied or CommandSupplied) then
            exit(false);
        if not (StaffSupplied and EmployeeIdSupplied and EmployeeNameSupplied and CommandSupplied) then
            Error('All employee attribution fields must be supplied together.');
        exit(true);
    end;

    local procedure WriteAttributed(IsInsert: Boolean)
    var
        Scope: Codeunit "VMS APL Attribution Scope";
    begin
        if IsInsert and IsNullGuid(Rec.SystemId) then
            Rec.SystemId := CreateGuid();
        Scope.Prepare(Rec, IsInsert, ModifiedByStaffId, ModifiedByEmployeeId, ModifiedByEmployeeName, ModificationCommandId);
        BindSubscription(Scope);
        if IsInsert then
            Rec.Insert(true, true)
        else
            Rec.Modify(true);
        UnbindSubscription(Scope);
        // The local binding also disappears if the record write raises an error.
        ModifiedByStaffId := Rec."VMS Staff ID";
        ModifiedByEmployeeId := Rec."VMS Employee ID";
        ModifiedByEmployeeName := Rec."VMS Employee Name";
        ModificationCommandId := Rec."VMS Command ID";
        ResetSupplied();
    end;

    local procedure ResetSupplied()
    begin
        StaffSupplied := false;
        EmployeeIdSupplied := false;
        EmployeeNameSupplied := false;
        CommandSupplied := false;
    end;
}

