# Bug Diagnosis - Market List Receive PO modal post-save error

**Date:** 2026-07-07
**Severity:** Medium
**Status:** Fixed

## Symptom

When a Purchase Order is opened from Market List Receiving and the user clicks **Post to Receive**, the receipt is posted, but the modal does not close and Business Central shows: "Purchase order header changes are not allowed when opened from Market List Receiving. You can only update Qty. to Receive on the lines."

**Reproducibility:** Specific condition: Purchase Order opened through Market List Receiving and posted through the custom **Post to Receive** action.

## Layer and category

- **Layer:** UI / Logic
- **Category:** Page action changes page `Rec`, then page close triggers `OnModifyRecord` guard.

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | Custom action mutates page `Rec` before posting, leaving the Purchase Order page dirty | HIGH | The action sets `Rec.Receive := true` and `Rec.Invoice := false`; the page then hits `OnModifyRecord` during close/save. |
| 2 | `CurrPage.Close()` itself is invalid after posting | LOW | The error text comes from this page extension's `OnModifyRecord`, not from close or posting code. |
| 3 | Standard posting flow is broken | LOW | The receipt is created; standard posting actions are separate and still hidden outside Market List mode. |

## Confirmed root cause

The custom `TBGC Post To Receive` action used the page `Rec` as the posting buffer. Setting `Rec.Receive` and `Rec.Invoice` marks the Purchase Order page header as changed. After `PurchPost.Run(Rec)` succeeds, `CurrPage.Close()` causes Business Central to process the dirty page record, which triggers `OnModifyRecord`. Because `MarketListReceivingMode` is true, `OnModifyRecord` raises `MarketListHeaderEditErr`.

## Proposed fix

Use a separate local `Purchase Header` record variable as the posting buffer. Load the same Purchase Order with `PurchHeader.Get(Rec."Document Type", Rec."No.")`, set `PurchHeader.Receive` and `PurchHeader.Invoice`, and call `PurchPost.Run(PurchHeader)`. Keep `CurrPage.Close()` after successful posting. This prevents the visible page `Rec` from becoming dirty while preserving the standard `Purch.-Post` posting process.

## Regression risk

Risk is low. The posting codeunit and receipt-only flags are unchanged; they are applied to a fresh `Purchase Header` variable instead of the page record. The standard Business Central posting actions are not modified.

## Tests required

- **Happy path:** Open a PO from Market List Receiving, click **Post to Receive**, confirm posting, verify the receipt posts and the modal closes without the header edit error.
- **Adjacent:** Open a regular Purchase Order outside Market List Receiving and use the standard post/receive action; verify behavior is unchanged.
- **Edge case:** Click **Post to Receive** and cancel the confirmation; verify the modal remains open and no posting occurs.