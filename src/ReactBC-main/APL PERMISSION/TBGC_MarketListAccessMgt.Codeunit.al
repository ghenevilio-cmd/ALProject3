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
