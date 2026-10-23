codeunit 80268 "VMS APL Attribution Guard"
{
    InherentPermissions = X;

    procedure ContractVersion(): Integer
    var
        Setup: Record "VMS APL Attribution Setup";
    begin
        if not Setup.ReadPermission then
            exit(0);
        if not Setup.Get('') then
            exit(0);
        if not Setup.Enabled or IsNullGuid(Setup."Integration User Security ID") then
            exit(0);
        if Setup."Integration User Security ID" <> UserSecurityId() then
            exit(0);
        exit(1);
    end;

    procedure AssertTrusted()
    begin
        if ContractVersion() <> 1 then
            Error('VMS employee attribution is not enabled for this integration user and company.');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Approved Product List", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "Approved Product List"; RunTrigger: Boolean)
    begin
        ClearStamp(Rec);
        OnStamp(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Approved Product List", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModify(var Rec: Record "Approved Product List"; var xRec: Record "Approved Product List"; RunTrigger: Boolean)
    begin
        ClearStamp(Rec);
        OnStamp(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Approved Product List", 'OnBeforeRenameEvent', '', false, false)]
    local procedure BeforeRename(var Rec: Record "Approved Product List"; var xRec: Record "Approved Product List"; RunTrigger: Boolean)
    begin
        ClearStamp(Rec);
    end;

    local procedure ClearStamp(var Price: Record "Approved Product List")
    begin
        Clear(Price."VMS Employee Name");
        Clear(Price."VMS Employee ID");
        Clear(Price."VMS Staff ID");
        Clear(Price."VMS Command ID");
        Clear(Price."VMS Attribution Source");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStamp(var Price: Record "Approved Product List"; IsInsert: Boolean)
    begin
    end;
}
