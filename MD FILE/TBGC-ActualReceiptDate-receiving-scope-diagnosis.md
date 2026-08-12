# Bug Diagnosis - Actual Receipt Date validation fires during PO creation

**Date:** 2026-07-09
**Severity:** High
**Status:** Fixed

## Symptom

During draft checkout / draft-to-PO creation, Business Central raises: "Actual Receipt Date is required for item A00300537 when Qty. to Receive is greater than zero." The field belongs to Market List Receiving, so PO creation should not require the user to enter an actual receipt date.

**Reproducibility:** Specific condition: a purchase line is created for a receivable item and Business Central validates/populates `Qty. to Receive` as part of normal PO line creation.

## Layer and category

- **Layer:** Logic / Integration
- **Category:** Unexpected validation from an event subscriber firing in the wrong workflow.

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | `Qty. to Receive` subscriber validates actual receipt date for all purchase line validations, including PO creation | HIGH | `PurchaseLineOnAfterValidateQtyToReceive` calls `ValidateActualReceiptDate(Rec)` unconditionally. |
| 2 | Draft converter should supply an actual receipt date | LOW | `TBGC Draft Order Line` has no actual receipt date field; the date is receiving data, not order creation data. |
| 3 | Post-to-receive action is missing validation | LOW | `TBGC Post To Receive` already calls `ValidatePurchaseOrderActualReceiptDates(PurchHeader)` before `PurchPost.Run`. |

## Confirmed root cause

The actual receipt date rule is scoped too broadly. The table event subscriber for `Purchase Line`.`Qty. to Receive` fires whenever that field is validated, including during purchase order creation when `Quantity` is validated. That makes a receiving-only field block Market List / draft PO creation.

## Proposed fix

Remove the draft-converter creation-time guard and scope `ValidateActualReceiptDate` in the `Qty. to Receive` subscriber to the existing Market List Receiving context. Keep the explicit `ValidatePurchaseOrderActualReceiptDates` call in the `Post to Receive` action so the field remains required during receiving/posting.

## Regression risk

Low. PO creation will no longer be blocked by a receiving-only field. Market List Receiving still validates the date when editing `Qty. to Receive` in receiving context and immediately before posting receipt.

## Tests required

- **Happy path:** Given draft checkout creates a PO line for item A00300537, when the PO is created, then no actual receipt date error is raised during creation.
- **Adjacent:** Given Market List Receiving is open for a PO and `Qty. to Receive` is greater than zero, when actual receipt date is blank, then the required-date error still appears.
- **Edge case:** Given `Post to Receive` is clicked with one positive `Qty. to Receive` line and blank actual receipt date, then posting is blocked before `Purch.-Post` runs.