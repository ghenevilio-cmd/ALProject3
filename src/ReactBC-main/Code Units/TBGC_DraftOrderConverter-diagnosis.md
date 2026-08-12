# Bug Diagnosis — Currency factor failure leaves header-only purchase order

**Date:** 2026-07-13
**Severity:** High
**Status:** Fixed - pending environment verification

## Symptom

Converting a draft order to a purchase order displays:

> Currency Factor must have a value in Purchase Header: Document Type=Order, No.=POR10000753. It cannot be zero or empty.

The failed conversion leaves a purchase order header with no purchase lines.

**Reproducibility:** Specific condition — the generated purchase header has a nonblank Currency Code but Currency Factor is zero.

## Layer and category

- **Layer:** Configuration / Logic / Data integrity
- **Category:** Posting or document validation failure followed by a partial/orphan record

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | The source vendor's currency requires an exchange rate for the effective document/posting date, but no applicable rate is available, leaving `Purchase Header`.`Currency Factor` at zero. | HIGH | The exact runtime error is the standard mandatory-value check for a nonblank purchase currency whose factor is zero. The converter derives the header from `Buy-from Vendor No.` and does not otherwise assign currency. Environment data must still be checked to identify the missing/invalid exchange-rate row. |
| 2 | Header prevalidation does not test `Currency Factor` and line prevalidation does not create/validate any temporary purchase lines. | CONFIRMED | `PreValidatePurchaseHeader` validates the vendor and dates but never calls `TestField("Currency Factor")` when `Currency Code` is nonblank. `PreValidateAllLines` only checks item existence, blocked state, quantity, and UOM; it does not execute the real `Purchase Line` validations that later require a valid header currency factor. |
| 3 | The page-level `TryFunction` preserves database writes made before the caught error, producing the header-only PO. | CONFIRMED | The real header is inserted at line 105 before lines are created at lines 118–124. Both card and list pages call the converter inside `[TryFunction]` and merely save the error afterward; neither deletes the partially created purchase document. |

## Confirmed root cause

`TBGC Draft Order Converter` claims that all validation has passed, then inserts the real purchase header (`PurchHeader.Insert(true)`) before the conversion has verified the invariant `Currency Code <> ''` implies `Currency Factor <> 0`. The missing check allows execution to reach real purchase-line validation, where Business Central raises the shown error. Because the caller catches that error through a page `[TryFunction]`, the already inserted header is not cleaned up and remains without lines.

The data condition triggering this path is a nonblank vendor-derived purchase currency with a zero factor. The most likely operational cause is a missing applicable Currency Exchange Rate for the selected document/posting date; this must be verified in the affected BC company before changing configuration.

## Proposed fix

Add a single pre-insert currency invariant check to the temporary-header prevalidation after vendor and manual document dates have been applied: when `Currency Code` is nonblank, require a nonzero `Currency Factor`. This makes the conversion fail before `PurchHeader.Insert(true)`, preventing new header-only purchase orders. Do not synthesize or hard-code a currency factor; correct the vendor/currency exchange-rate setup so valid conversions receive the standard Business Central factor. Existing header-only POs are a separate cleanup task and should be reviewed before deletion.

## Regression risk

Low. The check affects only draft-to-PO conversions using foreign currency and moves an existing mandatory validation earlier. Local-currency vendors should remain unchanged. Manual previous-date conversion is the adjacent risk because its selected posting/document date can require a different exchange-rate row.

## Tests required

- **Happy path:** Given a foreign-currency vendor with a valid exchange rate for the conversion date, when a draft with valid lines is converted, then the released PO header has a nonzero Currency Factor and all lines are created.
- **Adjacent:** Given a local-currency vendor with blank Currency Code, when a valid draft is converted, then conversion continues normally and creates/releases the PO.
- **Edge case:** Given a foreign-currency vendor with no applicable exchange rate for a manually selected previous posting/document date, when conversion is attempted, then it fails before allocating/inserting a real PO and no header-only PO remains.

## Skills Evidencing

| Field | Value |
|---|---|
| Skill loaded | bc-al-bug-fix |
| Symptom | Currency Factor error during draft-to-PO conversion; header remains without lines |
| Layer | Configuration / Logic / Data integrity |
| Root cause | Missing pre-insert currency invariant validation combined with caught post-insert error |
| Fix applied | Added the missing Currency Factor check to temporary-header prevalidation before the real PO header insert |
| Diagnosis doc | TBGC_DraftOrderConverter-diagnosis.md |
| Tests defined | 3 |
