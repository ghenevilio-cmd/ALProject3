# Bug Diagnosis - TBGC Original Ordered Qty on Posted Purchase Receipt Lines

**Date:** 2026-07-06
**Severity:** Medium
**Status:** Fixed

## Symptom

`TBGC Original Ordered Qty` should be inherited from purchase order lines into posted purchase receipt lines.

**Reproducibility:** Specific condition: purchase order receipt posting where the purchase line has a non-zero `TBGC Original Ordered Qty`.

## Layer and category

- **Layer:** Data / Integration
- **Category:** Regular field value missing after posting

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | Target posted receipt line table extension does not define the field | HIGH | `Purchase Line` has field `80299 "TBGC Original Ordered Qty"`; `Purch. Rcpt. Line` extension did not. |
| 2 | Existing receipt-line copy helper omits the field | HIGH | `TBGC Purchase Brand Transfer` copied brand code and actual receipt date only. |
| 3 | Posting event subscriber does not fire | LOW | Existing subscriber already handles posted receipt lines and is used for adjacent fields. |

## Confirmed root cause

`src/ReactBC-main/TBGC Brandcode/TBGC_PurchaseLineTableExt.al` defines field `80299 "TBGC Original Ordered Qty"` on `Purchase Line`, but `src/ReactBC-main/TBGC Brandcode/TBGC_PurchRcptLineTableExt.al` did not define the same field on `Purch. Rcpt. Line`. The existing receipt-line copy routine also did not assign this field.

## Proposed fix

Add `80299 "TBGC Original Ordered Qty"` to `Purch. Rcpt. Line` with the same type and metadata as the purchase line field, set it read-only on the posted table, and copy it in the existing purchase receipt line transfer helper.

## Regression risk

Low. The change adds a new stored field to posted purchase receipt lines and extends an existing copy routine. Adjacent risk is limited to receipt posting and undo receipt behavior.

## Tests required

- **Happy path:** Given a purchase order line with `TBGC Original Ordered Qty`, when receiving the line, then the posted purchase receipt line has the same value.
- **Adjacent:** Given a purchase order line with `TBGC Brand Code` and `TBGC Actual Receipt Date`, when receiving the line, then those existing values still copy to the posted receipt line.
- **Edge case:** Given a purchase order line where `TBGC Original Ordered Qty` is zero, when receiving the line, then the posted receipt line remains zero and posting succeeds.
