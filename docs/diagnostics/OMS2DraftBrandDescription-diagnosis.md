# Bug Diagnosis — Draft line brand description remains blank

**Date:** 2026-09-10
**Severity:** Medium
**Status:** Verified

## Symptom

Business Central Draft Order `DRF1000000011` contains valid `TBGC Brand Code` values, but `TBGC Brand Description` is blank on every Draft Order line created by OMS.

**Reproducibility:** Always for Draft Orders created through the OMSAPI2 v2 command path

## Layer and category

- **Layer:** Data / Integration
- **Category:** Direct assignment bypasses dependent-field population

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | OMSAPI2 v2 assigns only the Brand Code and never derives the Brand Description | HIGH | `OMS2CommandMgtV2.Codeunit.al` assigns `DraftLine."TBGC Brand Code"` directly and contains no description lookup or assignment. |
| 2 | Draft Line Brand Code validation should populate the description but is bypassed | MEDIUM | `TBGC Draft Order Line` has no `OnValidate` trigger on Brand Code, so even changing the caller to `Validate` alone cannot populate the description. |
| 3 | The description exists but the page fails to display it | LOW | The screenshot shows the page bound directly to the stored regular field, and no FlowField or page variable is involved. |

## Confirmed root cause

The v2 Draft creator introduced in `ae5479e` writes `DraftLine."TBGC Brand Code" := CommandLine."Brand Code"` and inserts the line without assigning `TBGC Brand Description`. The Draft Line table does not enforce the dependency. The older working `TBGC Draft Order Mgt` path explicitly writes the description received from its cart JSON, which is why this regression is specific to the new OMSAPI2 v2 path.

## Proposed fix

Make the Draft Line table own the relationship: when `TBGC Brand Code` is validated, resolve the matching composite `TBGC Brand List` record by Item No. plus Brand Code and copy its Business Central description; clear the description when the code is blank and reject an invalid item/brand combination. Change both Draft creators to call `Validate("TBGC Brand Code", ...)` and stop trusting a caller-supplied description. This uses Business Central master data as the single source of truth and fixes every supported Draft creation path in one rule.

## Regression risk

Draft creation will correctly fail when an item/brand pair is not configured in `TBGC Brand List`; previously the older path could store an arbitrary description supplied by the browser. Existing Draft rows are not automatically rewritten, so the current `DRF1000000011` remains unchanged unless it is recreated or a separately approved data repair is performed. Purchase Order conversion, numbering, release, currency, location, and receipt posting are outside this change and must continue to compile and pass their existing source contracts.

## Tests required

- **Happy path:** Given a configured Item No. and Brand Code, creating a Draft through OMSAPI2 v2 stores the matching `TBGC Brand Description`.
- **Adjacent:** Existing Market List Draft creation and Draft-to-PO conversion still preserve Brand Code and create a released Purchase Order.
- **Edge case:** A blank Brand Code clears the description; a nonblank item/brand combination absent from `TBGC Brand List` is rejected without leaving a partial Draft.
