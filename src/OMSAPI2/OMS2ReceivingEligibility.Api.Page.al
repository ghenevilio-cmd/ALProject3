/// <summary>
/// Whether the lines of one purchase order can be received at all, item by item, as Business Central sees it.
///
/// Four refusals live behind standard posting that OMS could not see, so a receiver met them only after the
/// receipt had been queued, refused and left for an administrator:
///  - the item is blocked, or blocked for purchasing;
///  - the line's location requires a warehouse receipt, so `Purch.-Post` will not receive it directly;
///  - the line carries no Shortcut Dimension 1 Code, which posting requires;
///  - the item carries no item family, so no receiving threshold applies and the ordered quantity is the ceiling.
///
/// The last is reported rather than refused: it is a setup gap, not an error, and stating it lets somebody fix
/// the family instead of wondering why an over-receipt was refused.
///
/// One row per purchase line of one order. Read-only, and filtered by the order it belongs to.
/// </summary>
page 80250 "OMS2 Receiving Eligibility API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'omsapi2';
    EntityCaption = 'OMS Receiving Eligibility';
    EntitySetCaption = 'OMS Receiving Eligibilities';
    EntityName = 'receivingEligibility';
    EntitySetName = 'receivingEligibilities';
    PageType = API;
    SourceTable = "Purchase Line";
    SourceTableView = where("Document Type" = const(Order), Type = const(Item));
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;
    AboutText = 'Reads whether each purchase line may be received: item blocks, warehouse receipt requirements and item family setup.';

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
                field(documentNumber; Rec."Document No.")
                {
                    Caption = 'Document Number';
                }
                field(lineNumber; Rec."Line No.")
                {
                    Caption = 'Line Number';
                }
                field(itemNumber; Rec."No.")
                {
                    Caption = 'Item Number';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                /// Blank refuses the posting: standard posting will not write a receipt line without it.
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(itemBlocked; ItemBlocked)
                {
                    Caption = 'Item Blocked';
                }
                field(itemPurchasingBlocked; ItemPurchasingBlocked)
                {
                    Caption = 'Item Purchasing Blocked';
                }
                field(itemFamilyCode; ItemFamilyCode)
                {
                    Caption = 'Item Family Code';
                }
                field(receivingThresholdPercent; ReceivingThresholdPercent)
                {
                    Caption = 'Receiving Threshold Percent';
                }
                field(locationRequiresReceive; LocationRequiresReceive)
                {
                    Caption = 'Location Requires Receive';
                }
                field(locationRequiresPutAway; LocationRequiresPutAway)
                {
                    Caption = 'Location Requires Put Away';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
        Location: Record Location;
        Threshold: Codeunit "OMS2 Receiving Threshold";
    begin
        Clear(ItemBlocked);
        Clear(ItemPurchasingBlocked);
        Clear(ItemFamilyCode);
        Clear(ReceivingThresholdPercent);
        Clear(LocationRequiresReceive);
        Clear(LocationRequiresPutAway);

        Item.SetLoadFields(Blocked, "Purchasing Blocked", "LSC Item Family Code");
        if Item.Get(Rec."No.") then begin
            ItemBlocked := Item.Blocked;
            ItemPurchasingBlocked := Item."Purchasing Blocked";
            ItemFamilyCode := Item."LSC Item Family Code";
        end;

        ReceivingThresholdPercent := Threshold.ThresholdPctForLine(Rec);

        // A blank location is the company's own inventory, which no warehouse receipt governs.
        if Rec."Location Code" <> '' then begin
            Location.SetLoadFields("Require Receive", "Require Put-away");
            if Location.Get(Rec."Location Code") then begin
                LocationRequiresReceive := Location."Require Receive";
                LocationRequiresPutAway := Location."Require Put-away";
            end;
        end;
    end;

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
    end;

    var
        ItemBlocked: Boolean;
        ItemPurchasingBlocked: Boolean;
        ItemFamilyCode: Code[10];
        ReceivingThresholdPercent: Decimal;
        LocationRequiresReceive: Boolean;
        LocationRequiresPutAway: Boolean;
}
