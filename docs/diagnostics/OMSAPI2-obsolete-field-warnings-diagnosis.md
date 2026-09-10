# Bug Diagnosis — OMSAPI2 obsolete-field warnings

**Date:** 2026-09-10
**Severity:** Low
**Status:** Diagnosed

## Symptom

After publishing extension version `1.1.2.16`, Visual Studio Code reports multiple `AL0432` diagnostics stating that the old OMS PO reference, receiving reference, and payload-hash fields are marked for removal.

**Reproducibility:** Always for current legacy v1 references; stale for files whose current lines no longer reference the fields

## Layer and category

- **Layer:** Integration
- **Category:** Obsolete API usage and stale editor diagnostics

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | Legacy OMSAPI2 v1 compatibility objects still reference fields now marked `ObsoleteState = Pending` | HIGH | A clean 150-file `alc.exe` build reports AL0432 only at the remaining v1 field references and exits successfully. |
| 2 | The AL language server retained diagnostics from an older source snapshot | HIGH | The reported Purchase Order page-extension and Draft converter lines no longer reference any obsolete field in the current files, and the clean compiler emits no warning for those locations. |
| 3 | Version `1.1.2.16` failed to compile or publish | LOW | The current source compiles with exit code 0 and no AL errors; the owner reports that publication succeeded. |

## Confirmed root cause

Version `1.1.2.16` deliberately marks published legacy fields as `ObsoleteState = Pending` so Business Central retains their field IDs during the safe upgrade. AL emits warning `AL0432` wherever the still-present v1 compatibility implementation reads those fields. The active v2 command implementation uses hidden command identities and does not require those fields. Some diagnostics shown by VS Code are stale because their reported files and line numbers no longer contain the references.

## Proposed fix

Do not republish or physically delete the published fields. Restart the AL language server to clear stale diagnostics. Keep the genuine v1 warnings until the OMS v2 application and Azure migrations are deployed and the old queue is proven drained; then remove the v1 objects and their internal references in a later extension version while retaining the published field declarations for upgrade compatibility. Do not suppress AL0432 globally because that would hide future accidental obsolete-field use.

## Regression risk

Removing v1 compatibility code before the OMS v2 cutover could break the currently deployed OMS worker or prevent already-queued v1 order/receipt messages from completing. Physically deleting published field IDs could make the Business Central extension upgrade destructive. The cleanup must therefore be gated by v2 deployment and an empty legacy queue.

## Tests required

- **Happy path:** Compile all AL source with zero errors and prove a v2 Draft command creates exactly one TBGC Draft Order.
- **Adjacent:** Prove the existing Draft-to-PO Job Queue conversion and standard receipt posting still complete.
- **Edge case:** Drain or replay one already-queued v1 command before removing its compatibility API, then prove no production worker still requests a v1 entity set.
