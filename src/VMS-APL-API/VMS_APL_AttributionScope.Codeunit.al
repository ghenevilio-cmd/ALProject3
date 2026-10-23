codeunit 80269 "VMS APL Attribution Scope"
{
    EventSubscriberInstance = Manual;
    InherentPermissions = X;

    var
        ExpectedId: Guid;
        ExpectedInsert: Boolean;
        ExpectedCompany: Text;
        StaffId: Integer;
        EmployeeId: Text[50];
        EmployeeName: Text[200];
        CommandId: Guid;
        Ready: Boolean;

    procedure Prepare(Price: Record "Approved Product List"; IsInsert: Boolean; NewStaffId: Integer; NewEmployeeId: Text; NewEmployeeName: Text; NewCommandId: Guid)
    var
        Guard: Codeunit "VMS APL Attribution Guard";
    begin
        Guard.AssertTrusted();
        if IsNullGuid(Price.SystemId) or (NewStaffId <= 0) or IsNullGuid(NewCommandId) then
            Error('A complete employee and operation identity is required.');
        ValidateText(NewEmployeeId, MaxStrLen(EmployeeId));
        ValidateText(NewEmployeeName, MaxStrLen(EmployeeName));
        ExpectedId := Price.SystemId;
        ExpectedInsert := IsInsert;
        ExpectedCompany := Price.CurrentCompany();
        if ExpectedCompany <> CompanyName() then
            Error('Cross-company employee attribution is not permitted.');
        StaffId := NewStaffId;
        EmployeeId := NewEmployeeId;
        EmployeeName := NewEmployeeName;
        CommandId := NewCommandId;
        Ready := true;
    end;

    local procedure ValidateText(Value: Text; MaximumLength: Integer)
    var
        Index: Integer;
        Character: Integer;
    begin
        if (Value = '') or (StrLen(Value) > MaximumLength) or (Value <> Value.Trim()) then
            Error('The employee identity is blank, too long or contains surrounding whitespace.');
        for Index := 1 to StrLen(Value) do begin
            Character := Value[Index];
            if (Character < 32) or ((Character >= 127) and (Character <= 159)) then
                Error('The employee identity contains an unsupported character.');
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VMS APL Attribution Guard", 'OnStamp', '', false, false)]
    local procedure Apply(var Price: Record "Approved Product List"; IsInsert: Boolean)
    var
        Guard: Codeunit "VMS APL Attribution Guard";
    begin
        if not Ready or (Price.SystemId <> ExpectedId) or (IsInsert <> ExpectedInsert) or (Price.CurrentCompany() <> ExpectedCompany) then
            exit;
        Ready := false;
        Guard.AssertTrusted();
        Price."VMS Employee Name" := EmployeeName;
        Price."VMS Employee ID" := EmployeeId;
        Price."VMS Staff ID" := StaffId;
        Price."VMS Command ID" := CommandId;
        Price."VMS Attribution Source" := 'VMS';
    end;
}
