codeunit 80286 "TBGC Market List Access Mgt"
{
    procedure IsCurrentUserAllowed(): Boolean
    begin
        exit(IsUserAllowed(CopyStr(UserId(), 1, 50)));
    end;

    procedure IsUserAllowed(UserSetupId: Code[50]): Boolean
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetupId = '' then
            exit(false);

        if not UserSetup.Get(UserSetupId) then
            exit(false);

        exit(UserSetup."TBGC Market List Permission" = UserSetup."TBGC Market List Permission"::ALLOWED);
    end;

    procedure IsCurrentUserTemplateMaster(): Boolean
    var
        Concept: Record "TBGC Concept Table";
    begin
        Concept.SetRange("Template Master", CopyStr(UserId(), 1, MaxStrLen(Concept."Template Master")));
        exit(not Concept.IsEmpty());
    end;

    procedure CanCurrentUserOrder(): Boolean
    begin
        exit(not (IsCurrentUserTemplateMaster() or IsCurrentUserAllowed()));
    end;

    procedure IsCurrentUserDeleteEditAllowed(): Boolean
    begin
        exit(IsUserDeleteEditAllowed(CopyStr(UserId(), 1, 50)));
    end;

    procedure IsUserDeleteEditAllowed(UserSetupId: Code[50]): Boolean
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetupId = '' then
            exit(false);

        if not UserSetup.Get(UserSetupId) then
            exit(false);

        exit(UserSetup."TBGC ML Del Edit");
    end;
}
