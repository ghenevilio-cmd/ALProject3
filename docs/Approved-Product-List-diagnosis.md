# Bug Diagnosis — APL API price replacement dates

**Date:** 2026-10-16
**Severity:** High
**Status:** Diagnosed; implementation authorized under Sol High

## Symptom
VMS price approval remains RECONCILIATION REQUIRED for A00000012/V002282,28->30 effective2026-11-01.
**Reproducibility:** Missing company User Setup blocks OnModify; future replacement contract defects follow deterministically from field triggers.

## Layer and category
Configuration: absent integration User Setup (user has now added it). Logic/integration: future end dates set Inactive immediately; blank Ending Date resets a new record's explicit Starting Date.

## Hypotheses
1. Missing User Setup — confirmed read-only for SYSTEM.AUTOMATE2 in Hungry Shrews before user repair.
2. Blocked vendor/item — ruled out by focused BC reads.
3. Date trigger mismatch — confirmed source and packaged1.1.2.24 match, independent of original missing-setup failure.

## Confirmed root cause
Table80266 ValidateAllowedItemFamily requires the integration User Setup. Do not bypass this guard. Ending Date OnValidate sets Inactive for any nonzero end and resets Starting Date whenever end is blank, conflicting with time-phased prices. Current-price consumers omit validity windows or exclude all finite ends.

## Proposed fix
Preserve active current prices until inclusive end, preserve explicit new-record start dates, retain permission-checked manual reactivation. Reuse a table validity predicate/filter in current-price consumers; keep administration/API exports capable of showing scheduled/history records. Use fixed labels for sensitive validation telemetry. VMS omits unnecessary blank end on insert and records only safe correlated error metadata. No automatic retry or data rewrite. Reviewed diagnosis presented; user confirmed Sol High implementation.

## Regression risk
Manual inactive/reactivation, today/end boundaries, report/POS/brand/purchase/history/draft selectors, finite source cloning. Existing inactive historical rows are not reactivated by migration. No schema change or upgrade data mutation is required.

## Tests required
- Happy: old28 active throughOct31; new30 only fromNov1; preserve requested start on insert.
- Adjacent: explicit inactive stays unavailable; manual reactivation still requires its permission; administration can inspect scheduled rows.
- Edge: inclusive ending day, blank boundaries, finite inheritance, duplicate reservation and uncertain result retain history. AL runtime tests require an approved isolated BC test execution; compiler/static checks alone are not runtime proof.

## Implementation evidence
Eight connected AL sources corrected locally. Main148-source app and separate four-method temporary-record test app compile with18.1.43.24897; source-contract check passes. AL runtime tests are not executed. VMS1954backend tests,515local SQL/HTTP checks and independent cleanup pass. Astra final review, versioned package, BC runtime verification and exact publication approval remain pending. No business-price replay/reconciliation. Main app.json stays1.1.2.24; preserve its pre-existing PASI dependency edit. Full evidence: VMS docs/reviews/pricing-date-diagnostics-implementation-2026-10-16.json.
