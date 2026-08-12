# Bug Diagnosis — Partial Receiving setup field cannot synchronize

**Date:** 2026-07-10
**Severity:** High
**Status:** Verified locally — cloud synchronization pending

## Symptom

Publishing version 1.0.1.24 with `SchemaUpdateMode=synchronize` fails with: `The field 'APL Show Partial Receiving' cannot be located. Removing fields is not allowed.`

**Reproducibility:** Always when upgrading a tenant where field 80299 was previously installed as Boolean `APL Show Partial Receiving`.

## Layer and category

- **Layer:** Data / Schema synchronization
- **Category:** Installed extension field was renamed and its data type changed.

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | Installed field 80299 was renamed, so synchronization treats the old field as removed | HIGH | Server explicitly reports that `APL Show Partial Receiving` cannot be located and removal is forbidden. |
| 2 | Changing field 80299 from Boolean to Integer is incompatible with synchronize | HIGH | The deployed schema has Boolean while the new source declares Integer under the same field ID. |
| 3 | New field ID collision prevents installation | LOW | Field 80293 is unused on `Purchases & Payables Setup`; current fields use 80294–80300 except 80293. |

## Confirmed root cause

Field 80299 was deployed as Boolean `APL Show Partial Receiving`, then changed in source to Integer `APL Partial Rcvg View Days`. Business Central cloud synchronization does not allow removing, renaming, or changing the type of an installed field. The source must retain the original field identity and type.

## Proposed fix

Restore field 80299 exactly as Boolean `APL Show Partial Receiving` and mark it obsolete-pending so it remains schema-compatible but is no longer used. Add Integer `APL Partial Rcvg View Days` as field 80293, which is unused on the target table and within the app ID range. Keep the setup page and receiving logic bound only to the new Integer field.

## Regression risk

The old Boolean value remains stored but unused. Existing companies receive `0` in the new Integer field, which intentionally means unlimited Partial visibility. The main regression check is ensuring field 80293 does not collide with another extension field on the same base table.

## Tests required

- **Happy path:** Publish over a tenant containing Boolean field 80299; synchronization completes without a field-removal error.
- **Adjacent:** Open Purchases & Payables Setup and verify the Integer visibility-days field is shown and saved.
- **Edge case:** Leave the new Integer at 0 and verify Partial orders remain visible indefinitely.

## Skills Evidencing

| Field | Value |
|---|---|
| Skill loaded | bc-al-bug-fix |
| Symptom | Cloud synchronization reports removed field `APL Show Partial Receiving` |
| Layer | Data / Schema synchronization |
| Root cause | Installed Boolean field 80299 was renamed and changed to Integer |
| Fix applied | Restored installed Boolean field 80299 and added Integer visibility-days field 80293 |
| Diagnosis doc | `MD FILE/APL-PartialReceiving-field-schema-diagnosis.md` |
| Tests defined | 3 |
