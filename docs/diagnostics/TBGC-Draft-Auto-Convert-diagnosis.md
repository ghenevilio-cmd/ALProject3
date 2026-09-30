# Bug Diagnosis — Draft auto conversion stops the batch

**Date:** 2026-09-25  
**Severity:** High  
**Status:** Local fix compiles; Business Central runtime verification pending

## Symptom

Job Queue codeunit 80213 fails with “An error occurred and the transaction is stopped.” The call stack ends in `AutoConvertReleasedDraftOrders` line 27. About 45 drafts have today's Released Date, and the sampled Open draft has no Last Error Message. A single manual conversion works.

**Reproducibility:** Repeated job and foreground runs. The first draft-level error is not yet known.

## Layer and category

- **Layer:** Logic / data integrity
- **Category:** Batch transaction boundary after a caught conversion failure

## Hypotheses

| Priority | Cause | Evidence |
|---|---|---|
| High | A failed draft writes Last Error Message, then the next guarded `Codeunit.Run` starts with an open write transaction. | The job calls the runner in a loop and calls `SetDraftConversionError`, which performs `Modify(true)`, in its failure branch. The reported call stack points to the job's runner call. |
| Medium | A draft-level validation or release error triggers the first failed runner. | The converter has several validation and release steps, but the original error is lost when the outer job stops. |
| Low | A background-only UI callback fails. | The same failure occurs when the job is run in the foreground. |

## Confirmed root cause

The source has an uncommitted database write between guarded `Codeunit.Run` calls when one draft fails and another follows. Business Central requires the caller's write transaction to finish before another guarded `Codeunit.Run`. The first draft-level error and the exact affected draft remain unconfirmed until a corrected batch runs.

## Number-series finding

The user changed **TBGC Draft Order Nos.** in Purchases & Payables Setup. `TBGC Draft Order Header.OnInsert` reads that field only when assigning a number to a newly inserted draft whose No. is blank. The existing 45 drafts already have numbers, and the draft-to-PO converter does not read this custom field. The converter calls `Purchase Header.Insert(true)` for a new PO; standard Purchase Orders use the separate **Order Nos.** setup field. Manual conversion uses the same Purchase Header insertion path and reportedly works. The changed draft number series is therefore not a direct explanation for the existing-draft batch failure; the first per-draft error still requires a runtime run to identify.

## Proposed fix

Buffer failed draft numbers and error text in a temporary record, then persist the errors after the runner loop. Do not add an explicit `Commit` in the conversion path. For the job path, reject a draft already linked to a Purchase Order before inserting a new header. Before marking a draft Converted, re-read the created Purchase Order, require Released status, and require item-line count to match the draft-line count. Manual conversion behavior remains unchanged.

## Regression risk

The new job-only checks may reject drafts with an existing linked PO or release customizations that return without a Released status; these are intentional stops to prevent duplicate or Open POs. A called extension that commits internally could still leave partial data after an error, so rollback must be checked in the target Business Central environment.

## Tests required

- **Happy path:** Given a valid Open draft released today, when the job runs, then one Released PO with every expected item line exists and the draft is Converted.
- **Adjacent:** Given one invalid draft followed by a valid draft, when the job runs, then the invalid draft remains Open with its error and no PO, while the valid draft converts. A single manual conversion continues to work.
- **Edge case:** Given a draft already linked to an Open PO, or a release operation that leaves a PO Open, when the job runs, then it does not mark the draft Converted or create a second PO. Verify no header-only PO remains after a line or release failure.
