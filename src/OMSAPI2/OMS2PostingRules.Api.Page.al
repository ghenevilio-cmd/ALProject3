/// <summary>
/// The company-wide rules a receipt has to satisfy, in one read, so OMS can refuse a receipt Business Central
/// would refuse instead of discovering it a round trip later.
///
/// Two facts live here because both are date bounds on the same posting date:
///  - the allowed posting window from General Ledger Setup;
///  - the newest closed inventory period, which Business Central will not let an item posting fall on or before.
///
/// Both are read, never written. A blank date means that bound is open, which is how Business Central stores
/// "no limit". Item and location rules are per document rather than per company and are answered by their own
/// pages.
/// </summary>
page 80247 "OMS2 Posting Rules API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Posting Rule';
    EntitySetCaption = 'OMS Posting Rules';
    EntityName = 'postingRule';
    EntitySetName = 'postingRules';
    PageType = API;
    SourceTable = "General Ledger Setup";
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;
    AboutText = 'Reads the posting window and the newest closed inventory period so OMS can validate a posting date.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                }
                field(allowPostingFrom; Rec."Allow Posting From")
                {
                    Caption = 'Allow Posting From';
                }
                field(allowPostingTo; Rec."Allow Posting To")
                {
                    Caption = 'Allow Posting To';
                }
                field(lastClosedInventoryPeriod; LastClosedInventoryPeriod)
                {
                    Caption = 'Last Closed Inventory Period';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LastClosedInventoryPeriod := NewestClosedPeriodEnding();
    end;

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
    end;

    /// <summary>
    /// The ending date of the newest closed inventory period. Business Central refuses an item posting dated on
    /// or before it, so OMS treats the day after as the earliest date a receipt may carry.
    /// </summary>
    local procedure NewestClosedPeriodEnding(): Date
    var
        InventoryPeriod: Record "Inventory Period";
    begin
        InventoryPeriod.SetLoadFields("Ending Date");
        InventoryPeriod.SetRange(Closed, true);
        if InventoryPeriod.FindLast() then
            exit(InventoryPeriod."Ending Date");

        exit(0D);
    end;

    var
        LastClosedInventoryPeriod: Date;
}
