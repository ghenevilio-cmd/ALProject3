# Bug Diagnosis — Fully Received Market List order remains editable

**Date:** 2026-07-10
**Severity:** High
**Status:** Verified

## Symptom

When a purchase order with display status **Fully Received** is opened from Market List Receiving, the Purchase Order page still allows editing. A fully received order should be view-only in this entry path.

**Reproducibility:** Always when the order is classified as Fully Received and opened from Market List Receiving.

## Layer and category

- **Layer:** UI / Logic
- **Category:** Page editability state is not propagated from the originating status.

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | Fully Received uses the same editable opening path as other receiving statuses | HIGH | `OpenReceivingDocument` calls `OpenMarketListPurchaseOrder` for Fully Received and for other statuses. |
| 2 | Market List context does not carry a read-only flag | HIGH | `TBGC ML Receiving Context` stores only `CurrentPurchaseOrderNo`. |
| 3 | Purchase Order Subform explicitly forces receiving fields editable | HIGH | `Qty. to Receive` and `TBGC Actual Receipt Date` both use `Editable = true`. |

## Confirmed root cause

`TBGC Receiving Mgt`.`OpenReceivingDocument` detects `DisplayStatus = 'Fully Received'`, but then calls the same `OpenMarketListPurchaseOrder(PurchHeader)` procedure used for Released, Late Released, and Partial orders. `TBGC ML Receiving Context` only records the purchase order number, so the Purchase Order page and subpage cannot distinguish Fully Received from an editable receiving session. In addition, the subpage explicitly sets the two receiving fields to editable.

## Proposed fix

Extend the existing Market List Receiving context with a read-only Boolean. Pass `true` only when opening a Fully Received order. On the Purchase Order page extension, apply `CurrPage.Editable(false)` for that context and hide the custom **Post to Receive** action. On the Purchase Order Subform extension, make `Qty. to Receive` and `TBGC Actual Receipt Date` editable only when the Market List context is not read-only. Preserve current behavior for Released, Late Released, and Partial orders.

## Regression risk

The main risk is accidentally making Released, Late Released, or Partial orders read-only. The context must be cleared when the page closes and must default to false. Opening a purchase order normally outside Market List Receiving must remain unchanged.

## Tests required

- **Happy path:** Given a Fully Received PO opened from Market List Receiving, when the Purchase Order page opens, then header, lines, Qty. to Receive, Actual Receipt Date, and Post to Receive are not editable/available.
- **Adjacent:** Given a Partial PO opened from Market List Receiving, when the page opens, then Qty. to Receive and Actual Receipt Date remain editable.
- **Edge case:** Given the same Fully Received PO opened normally from the Purchase Orders list, when the page opens, then standard Business Central editability rules apply and no Market List read-only state leaks into the session.

## Skills Evidencing

| Field | Value |
|---|---|
| Skill loaded | bc-al-bug-fix |
| Symptom | Fully Received order remains editable from Market List Receiving |
| Layer | UI / Logic |
| Root cause | Read-only status is not propagated through the Market List context |
| Fix applied | Propagated a read-only context for Fully Received orders and disabled the page/subpage receiving controls |
| Diagnosis doc | `MD FILE/TBGC-FullyReceived-MarketList-readonly-diagnosis.md` |
| Tests defined | 3 |
