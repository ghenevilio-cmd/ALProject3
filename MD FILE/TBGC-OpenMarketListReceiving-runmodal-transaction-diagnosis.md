# Bug Diagnosis - Market List Receiving cannot open Purchase Order

**Date:** 2026-07-09
**Severity:** High
**Status:** Fixed

## Symptom

Opening a Purchase Order from Market List Receiving fails with: "Form.RunModal is not allowed in write transactions." The call stack points to `TBGC Receiving Mgt.OpenMarketListPurchaseOrder` at the `PAGE.RunModal(Page::"Purchase Order", PurchHeader)` call.

**Reproducibility:** When opening OPEN PO / RECEIVING PO from the Market List Receiving page while a write transaction is active.

## Layer and category

- **Layer:** UI / Integration
- **Category:** Page open attempted inside active write transaction.

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | `PAGE.RunModal` is called while a write transaction remains active | HIGH | Error explicitly says `Form.RunModal is not allowed in write transactions`; call stack points to `OpenMarketListPurchaseOrder`. |
| 2 | Recent receipt-date validation causes this exact RunModal error | LOW | The receipt-date validation is not in the call stack; this error happens before the Purchase Order page opens. |
| 3 | Purchase Order page itself raises the error | LOW | BC reports the blocked method is the caller's `PAGE.RunModal`, not page logic after opening. |

## Confirmed root cause

`OpenMarketListPurchaseOrder` committed only when `RefreshMarketListPostingDate` or `ResetQtyToReceiveForMarketList` reported a local change. However, Business Central can still be inside a write transaction started earlier in the page/control-addin call flow. Calling `PAGE.RunModal` before closing that transaction raises the runtime error.

## Proposed fix

Commit unconditionally after the Market List receiving preparation routines and immediately before setting the receiving context and opening the Purchase Order page. This keeps the existing page-open behavior but guarantees `RunModal` is outside the active write transaction.

## Regression risk

Low to medium. This changes the transaction boundary for opening a Purchase Order from Market List Receiving. The preparation writes were already committed in some cases; this makes the commit consistent for all cases.

## Tests required

- **Happy path:** Given a PO in OPEN/RECEIVING status, when opened from Market List Receiving, then the Purchase Order page opens without the RunModal write-transaction error.
- **Adjacent:** Given the PO has nonzero `Qty. to Receive`, when opened from Market List Receiving, then quantities are reset and the page opens.
- **Edge case:** Given a fully received PO, when opened from Market List Receiving, then the Purchase Order page still opens read-only/receiving-mode as before.