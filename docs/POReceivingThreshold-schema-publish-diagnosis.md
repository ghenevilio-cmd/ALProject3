# Bug Diagnosis — Receiving threshold field removal blocks publish

**Date:** 2026-07-10
**Severity:** High
**Status:** Verified

## Symptom

Publishing version `1.0.1.24` with `SchemaUpdateMode=synchronize` fails with `UnprocessableEntity`: `TableExtension 80293 TBGC PO Rcvg Threshold Setup :: The field 'TBGC PO Rcvg Threshold %' cannot be located. Removing fields is not allowed.` Business Central restores the original extension.

**Reproducibility:** Always when upgrading an environment that has the earlier schema containing this field.

## Layer and category

- **Layer:** Data / extension schema synchronization
- **Category:** Upgrade schema compatibility

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | Published field 80297 was deleted from table extension 80293 | HIGH | The server names the missing field and object; the current source no longer declares it there. |
| 2 | Field ID or type was changed in place | LOW | The new Item Family field uses ID 80297 on a different base table, but the original table-extension schema entry is absent rather than changed. |
| 3 | Dependency or tenant mismatch | LOW | Compilation succeeds and the publish failure is specifically a destructive schema-change rejection. |

## Confirmed root cause

The previous published version added field 80297 `TBGC PO Rcvg Threshold %` to `Purchases & Payables Setup` through table extension 80293. Moving the configuration deleted that field declaration and created a separate field on `LSC Item Family`. Business Central treats these as unrelated physical fields and does not allow the original field to disappear during `Synchronize`.

## Proposed fix

Restore field 80297 with its original name and Decimal definition in table extension 80293, mark it obsolete pending with a reason directing developers to the Item Family field, and leave it absent from the Purchases & Payables Setup page and runtime receiving logic. The field remains only for schema compatibility; Item Family stays authoritative.

## Regression risk

Low. Reintroducing the exact legacy field restores the previously published schema. The main risk is accidentally reading the legacy value again; static reference checks will verify that receiving logic only reads the Item Family field.

## Tests required

- **Happy path:** Publish with `SchemaUpdateMode=synchronize` over version 1.0.1.24; installation succeeds without the field-removal error.
- **Adjacent:** Compile and confirm purchase receiving resolves the threshold through Item → LSC Item Family.
- **Edge case:** A company with an existing legacy setup value upgrades successfully, while that old value remains unused and hidden.


## Verification result

- Restored the exact legacy field declaration as obsolete pending and left it off the setup page.
- Static assertion confirms runtime receiving code has no read of the legacy setup field.
- Full AL compilation completed successfully for all 114 files with zero errors.
- Cloud publication remains the final environment-level verification because it requires the target tenant.
