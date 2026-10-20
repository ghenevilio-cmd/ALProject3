# Bug Diagnosis — Receipt concept mapping

**Date:** 2026-10-20
**Severity:** High
**Status:** Implemented and compiled locally; final Astra review and BC runtime tests pending.

## Symptom
VMS disputes for location1991 are absent in OMS's DENNYS scope.

## Layer and category
Integration/data: wrong source field under a shared API name.

## Hypotheses
1. Wrong field mapping (confirmed): receipt conceptCode uses Shortcut Dimension1 while OMS store concept uses LSC Store TBGC Concept Code.
2. Company/store permissions (not root cause): exact current scope checks are behaving as coded.

## Confirmed root cause
Posted receipt page80261 fieldconceptCode references receipt accounting dimension1991. Store page80242 exposes purchasing conceptDENNYS. Undo codeunit80262 also compares ExpectedConceptCode to that accounting dimension.

## Proposed fix
Reviewed contract2 separates concept and raw dimension, obtains the unique same-company LSC store concept, retires legacy Undo and validates both values before standard single-line UndoV2. Dedicated read permission gains LSC Store read and mapping-codeunit execution only.

## Regression risk / tests required
Realistic1991/DENNYS mapping, missing/duplicate/blank mapping, no prior-row variable leakage, version1 refusal, two expected meanings, per-line invoice/identity/quantity/standard-Undo safeguards. AL tests use temporary LSC records and must be run in BC before claiming runtime acceptance. No hosted publication or financial reversal is included.
