#if VMS_APL_ATTRIBUTION_TESTS
codeunit 80352 "VMS APL Attribution Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingOrWrongCallerIsDenied()
    var
        Setup: Record "VMS APL Attribution Setup";
        Guard: Codeunit "VMS APL Attribution Guard";
        Scope: Codeunit "VMS APL Attribution Scope";
        Price: Record "Approved Product List" temporary;
    begin
        Setup.DeleteAll();
        if Guard.ContractVersion() <> 0 then Error('Missing setup must deny.');
        Configure(CreateGuid());
        Price.SystemId := CreateGuid();
        asserterror Scope.Prepare(Price, true, 7, '29957', 'Employee', CreateGuid());
        if Guard.ContractVersion() <> 0 then Error('Wrong security ID must deny.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrustedInsertAndModifyStampOneRecord()
    var
        Price: Record "Approved Product List" temporary;
    begin
        Configure(UserSecurityId());
        Price."Entry No." := 1;
        Price.SystemId := CreateGuid();
        WriteStamped(Price, true);
        AssertName(Price, 'Employee');
        WriteStamped(Price, false);
        AssertName(Price, 'Employee');
        if not IsNullGuid(Price.SystemModifiedBy) and (Price.SystemModifiedBy <> UserSecurityId()) then
            Error('The system audit identity must remain the real BC caller.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ModifyFalseClearsEarlierEmployee()
    var
        Price: Record "Approved Product List" temporary;
    begin
        Configure(UserSecurityId());
        Price."Entry No." := 1;
        Price.SystemId := CreateGuid();
        WriteStamped(Price, true);
        Price.Modify(false);
        AssertName(Price, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CopiedInsertCannotInheritEmployee()
    var
        Price: Record "Approved Product List" temporary;
        Other: Record "Approved Product List" temporary;
    begin
        Configure(UserSecurityId());
        Price."Entry No." := 1;
        Price.SystemId := CreateGuid();
        WriteStamped(Price, true);
        Other := Price;
        Other."Entry No." := 2;
        Other.SystemId := CreateGuid();
        Other.Insert(false, true);
        AssertName(Other, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScopeDisappearsAfterError()
    var
        Price: Record "Approved Product List" temporary;
    begin
        Configure(UserSecurityId());
        Price."Entry No." := 1;
        Price.SystemId := CreateGuid();
        Price.Insert(false, true);
        if FailWithBoundScope(Price) then Error('Expected the bound procedure to fail.');
        Price.Modify(false);
        AssertName(Price, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BulkModifyAndRenameClearEmployee()
    var
        Price: Record "Approved Product List" temporary;
    begin
        Configure(UserSecurityId());
        Price."Entry No." := 1;
        Price.SystemId := CreateGuid();
        WriteStamped(Price, true);
        Price.ModifyAll("Direct Unit Cost", 20, false);
        Price.Get(1);
        AssertName(Price, '');
        WriteStamped(Price, false);
        Price.Rename(2);
        AssertName(Price, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectIncompleteOrOversizedIdentity()
    var
        Scope: Codeunit "VMS APL Attribution Scope";
        Price: Record "Approved Product List" temporary;
    begin
        Configure(UserSecurityId());
        Price.SystemId := CreateGuid();
        asserterror Scope.Prepare(Price, true, 0, '29957', 'Employee', CreateGuid());
        asserterror Scope.Prepare(Price, true, 7, '', 'Employee', CreateGuid());
        asserterror Scope.Prepare(Price, true, 7, '29957', ' Employee', CreateGuid());
        asserterror Scope.Prepare(Price, true, 7, '29957', PadStr('', 201, 'x'), CreateGuid());
    end;

    local procedure Configure(SecurityId: Guid)
    var
        Setup: Record "VMS APL Attribution Setup";
    begin
        if not Setup.Get('') then begin
            Setup.Init();
            Setup.Insert();
        end;
        Setup.Enabled := true;
        Setup."Integration User Security ID" := SecurityId;
        Setup.Modify();
    end;

    local procedure WriteStamped(var Price: Record "Approved Product List"; IsInsert: Boolean)
    var
        Scope: Codeunit "VMS APL Attribution Scope";
    begin
        Scope.Prepare(Price, IsInsert, 7, '29957', 'Employee', CreateGuid());
        BindSubscription(Scope);
        if IsInsert then Price.Insert(false, true) else Price.Modify(false);
    end;

    [TryFunction]
    local procedure FailWithBoundScope(Price: Record "Approved Product List")
    var
        Scope: Codeunit "VMS APL Attribution Scope";
    begin
        Scope.Prepare(Price, false, 7, '29957', 'Employee', CreateGuid());
        BindSubscription(Scope);
        Error('Test error after binding, before any database write.');
    end;

    local procedure AssertName(Price: Record "Approved Product List"; Expected: Text)
    var
        Ref: RecordRef;
        Value: FieldRef;
    begin
        Ref.GetTable(Price);
        Value := Ref.Field(30);
        if Format(Value.Value) <> Expected then Error('Unexpected employee attribution.');
    end;
}
#endif
