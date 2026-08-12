codeunit 80220 "TBGC ML Ordering Day Mgt"
{
    procedure IsTodayOrderingDay(): Boolean
    var
        OrderingDaySetup: Record "TBGC ML Ordering Day Setup";
    begin
        if not OrderingDaySetup.Get('DEFAULT') then
            exit(true);

        exit(IsDateOrderingDay(Today, OrderingDaySetup));
    end;

    procedure IsTodayDraftOrderingDay(): Boolean
    var
        OrderingDaySetup: Record "TBGC ML Ordering Day Setup";
    begin
        if not OrderingDaySetup.Get('DEFAULT') then
            exit(true);

        exit(IsDateDraftOrderingDay(Today, OrderingDaySetup));
    end;

    procedure GetAllowFromTime(): Text
    var
        OrderingDaySetup: Record "TBGC ML Ordering Day Setup";
    begin
        if not OrderingDaySetup.Get('DEFAULT') then
            exit('');

        exit(FormatSetupTime(OrderingDaySetup."Allow From Time"));
    end;

    procedure GetAllowToTime(): Text
    var
        OrderingDaySetup: Record "TBGC ML Ordering Day Setup";
    begin
        if not OrderingDaySetup.Get('DEFAULT') then
            exit('');

        exit(FormatSetupTime(OrderingDaySetup."Allow To Time"));
    end;

    procedure GetDraftAllowFromTime(): Text
    var
        OrderingDaySetup: Record "TBGC ML Ordering Day Setup";
    begin
        if not OrderingDaySetup.Get('DEFAULT') then
            exit('');

        exit(FormatSetupTime(OrderingDaySetup."Draft Allow From Time"));
    end;

    procedure GetDraftAllowToTime(): Text
    var
        OrderingDaySetup: Record "TBGC ML Ordering Day Setup";
    begin
        if not OrderingDaySetup.Get('DEFAULT') then
            exit('');

        exit(FormatSetupTime(OrderingDaySetup."Draft Allow To Time"));
    end;

    local procedure FormatSetupTime(TimeValue: Time): Text
    begin
        if TimeValue = 0T then
            exit('');

        exit(Format(TimeValue, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    local procedure IsDateOrderingDay(DateToCheck: Date; OrderingDaySetup: Record "TBGC ML Ordering Day Setup"): Boolean
    begin
        case Date2DWY(DateToCheck, 1) of
            1:
                exit(OrderingDaySetup."Allow Monday");
            2:
                exit(OrderingDaySetup."Allow Tuesday");
            3:
                exit(OrderingDaySetup."Allow Wednesday");
            4:
                exit(OrderingDaySetup."Allow Thursday");
            5:
                exit(OrderingDaySetup."Allow Friday");
            6:
                exit(OrderingDaySetup."Allow Saturday");
            7:
                exit(OrderingDaySetup."Allow Sunday");
        end;

        exit(true);
    end;

    local procedure IsDateDraftOrderingDay(DateToCheck: Date; OrderingDaySetup: Record "TBGC ML Ordering Day Setup"): Boolean
    begin
        case Date2DWY(DateToCheck, 1) of
            1:
                exit(OrderingDaySetup."Draft Allow Monday");
            2:
                exit(OrderingDaySetup."Draft Allow Tuesday");
            3:
                exit(OrderingDaySetup."Draft Allow Wednesday");
            4:
                exit(OrderingDaySetup."Draft Allow Thursday");
            5:
                exit(OrderingDaySetup."Draft Allow Friday");
            6:
                exit(OrderingDaySetup."Draft Allow Saturday");
            7:
                exit(OrderingDaySetup."Draft Allow Sunday");
        end;

        exit(true);
    end;
}
