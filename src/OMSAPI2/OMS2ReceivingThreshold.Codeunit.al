/// <summary>
/// The receiving threshold as OMS needs to see it: how much more than the ordered quantity a purchase line
/// may still accept, configured per Item Family.
///
/// The rule already exists for people working inside Business Central, in codeunit 80293
/// "TBGC PO Rcvg Threshold Mgt". Its validation subscribers deliberately return early on a programmatic
/// validate (`CurrFieldNo = 0`) so posting is never interrupted by a confirmation dialog — and OMS posts its
/// receipts exactly that way, from code. So the rule is invisible to OMS, and this states the same arithmetic
/// where OMS can read it: the ordered quantity, plus its family's percentage, less whatever Business Central
/// has already received.
///
/// Baseline and ceiling are computed the same way as codeunit 80293, so a quantity OMS accepts is a quantity
/// Business Central accepts. Anything else would refuse a receipt in one place and allow it in the other.
/// </summary>
codeunit 80250 "OMS2 Receiving Threshold"
{
    Access = Public;

    /// <summary>The percentage over the ordered quantity the item's family still allows, or zero.</summary>
    procedure ThresholdPctForItem(ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
        ItemFamily: Record "LSC Item Family";
    begin
        if ItemNo = '' then
            exit(0);

        Item.SetLoadFields("LSC Item Family Code");
        if not Item.Get(ItemNo) then
            exit(0);

        if Item."LSC Item Family Code" = '' then
            exit(0);

        ItemFamily.SetLoadFields("TBGC PO Rcvg Threshold %");
        if not ItemFamily.Get(Item."LSC Item Family Code") then
            exit(0);

        exit(ItemFamily."TBGC PO Rcvg Threshold %");
    end;

    procedure ThresholdPctForLine(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit(0);

        exit(ThresholdPctForItem(PurchaseLine."No."));
    end;

    /// <summary>
    /// The most that may ever be received against the line in total. Standard over-receipt handling raises the
    /// line quantity itself, so the original ordered quantity is the baseline whenever it was captured; using
    /// the current quantity would let each over-receipt raise the ceiling for the next one.
    /// </summary>
    procedure MaxTotalReceivable(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        exit(OriginalOrderedQty(PurchaseLine) * (1 + (ThresholdPctForLine(PurchaseLine) / 100)));
    end;

    /// <summary>What may still be received now: the ceiling less what has already been received.</summary>
    procedure RemainingReceivable(PurchaseLine: Record "Purchase Line"): Decimal
    var
        Remaining: Decimal;
    begin
        Remaining := MaxTotalReceivable(PurchaseLine) - PurchaseLine."Quantity Received";
        if Remaining < 0 then
            exit(0);

        exit(Remaining);
    end;

    procedure OriginalOrderedQty(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        if PurchaseLine."TBGC Original Ordered Qty" <> 0 then
            exit(PurchaseLine."TBGC Original Ordered Qty");

        exit(PurchaseLine.Quantity);
    end;

    /// <summary>
    /// Refuses a quantity the item's family does not allow, naming the ceiling so the receiver knows the limit
    /// rather than guessing at it. Same arithmetic and same wording as codeunit 80293, so the answer does not
    /// depend on whether the receipt came from OMS or from a person working in Business Central.
    /// </summary>
    procedure AssertWithinThreshold(PurchaseLine: Record "Purchase Line"; QuantityToReceive: Decimal)
    var
        MaxAllowedQty: Decimal;
    begin
        MaxAllowedQty := MaxTotalReceivable(PurchaseLine);
        if PurchaseLine."Quantity Received" + QuantityToReceive <= MaxAllowedQty then
            exit;

        Error(
          'Qty. to Receive for item %1 cannot make the total received quantity exceed %2. The original ordered quantity is %3 and the PO Receiving Threshold is %4%.',
          PurchaseLine."No.",
          MaxAllowedQty,
          OriginalOrderedQty(PurchaseLine),
          ThresholdPctForLine(PurchaseLine));
    end;

    /// <summary>
    /// Lets a receipt within the family's threshold through standard posting.
    ///
    /// Standard Business Central refuses a Qty. to Receive above the outstanding quantity unless the line
    /// carries an Over-Receipt Code permitting it, and raises the line quantity itself once it does. So this
    /// stamps that standard field and changes nothing about posting: `Purch.-Post` runs untouched and makes
    /// the same decision it makes for a receipt entered by hand.
    ///
    /// Codeunit 80293 does exactly this for the Business Central UI, but its helpers are `local` and cannot be
    /// called from here. The code name is derived from the percentage, so both paths resolve to the same
    /// Over-Receipt Code record rather than creating competing ones — and a tolerance that disagrees with the
    /// item family is refused instead of silently widening what may be received.
    /// </summary>
    procedure ApplyThresholdAllowance(var PurchaseLine: Record "Purchase Line"; QuantityToReceive: Decimal)
    var
        OverReceiptCode: Record "Over-Receipt Code";
        ThresholdPct: Decimal;
        CodeValue: Code[20];
    begin
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit;

        // Nothing beyond the ordered quantity is being received, so standard posting needs no allowance.
        if PurchaseLine."Quantity Received" + QuantityToReceive <= OriginalOrderedQty(PurchaseLine) then
            exit;

        ThresholdPct := ThresholdPctForLine(PurchaseLine);
        if ThresholdPct <= 0 then
            exit;

        CodeValue := CopyStr(
            StrSubstNo('TBGC%1', Format(Round(ThresholdPct * 100000, 1, '='), 0, 9)),
            1,
            MaxStrLen(CodeValue));

        if OverReceiptCode.Get(CodeValue) then begin
            if OverReceiptCode."Over-Receipt Tolerance %" <> ThresholdPct then
                Error(OverReceiptCodeMismatchErr, OverReceiptCode.Code, OverReceiptCode."Over-Receipt Tolerance %", ThresholdPct);
        end else begin
            OverReceiptCode.Init();
            OverReceiptCode.Code := CodeValue;
            OverReceiptCode.Description := CopyStr(StrSubstNo('TBGC PO Receiving Threshold %1%', ThresholdPct), 1, MaxStrLen(OverReceiptCode.Description));
            OverReceiptCode."Over-Receipt Tolerance %" := ThresholdPct;
            OverReceiptCode.Insert(false);
        end;

        if PurchaseLine."Over-Receipt Code" <> OverReceiptCode.Code then
            PurchaseLine."Over-Receipt Code" := OverReceiptCode.Code;
    end;

    var
        OverReceiptCodeMismatchErr: Label 'Over-Receipt Code %1 has tolerance %2%%, but the item family requires %3%%. Correct the Over-Receipt Code before receiving.';
}
