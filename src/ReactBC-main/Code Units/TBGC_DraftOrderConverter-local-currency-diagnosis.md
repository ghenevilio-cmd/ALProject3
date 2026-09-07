# Bug Diagnosis — OMS local currency is treated as foreign currency

**Date:** 2026-09-07
**Severity:** High
**Status:** Fixed — compiled, pending sandbox verification

## Symptom

Converting an OMS-created TBGC Draft Order reports:

> Currency Factor must have a value in Purchase Header: Document Type=Order, No.=VALIDATION. It cannot be zero or empty.

Other standard purchase orders in the same Business Central company show a zero Currency Factor.

**Reproducibility:** OMS order currency is sent as the company's local-currency code while standard Business Central represents local currency with a blank Purchase Header Currency Code.

## Layer and category

- **Layer:** Integration / Logic
- **Category:** Document validation failure caused by local-currency representation mismatch

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | OMS sends the ISO local-currency code, but the converter writes it as a nonblank Purchase Header Currency Code, making Business Central treat it as foreign currency. | Confirmed | OMS orders default to `PHP`; the mapper sends that value unchanged. `OMS2 Draft Orders API` requires it, and the converter validates it onto the temporary Purchase Header. The error names the temporary header `VALIDATION`. |
| 2 | A genuinely foreign-currency order has no exchange rate for its document date. | Possible for other currencies, not this local-currency case | The existing prevalidation correctly rejects any nonblank foreign currency whose factor remains zero. That check must stay. |
| 3 | Zero is always an invalid Currency Factor. | Rejected | A zero factor is standard for a local-currency Purchase Header when Currency Code is blank; the user's normal purchase orders demonstrate that state. |

## Confirmed root cause

OMS and Business Central use different representations for the same local currency. OMS persists an explicit
three-letter ISO currency (`PHP`). The affected vendors have a blank Vendor Currency Code, so standard Business
Central correctly initializes their Purchase Headers with a blank Currency Code and a zero Currency Factor.

`TBGC Draft Order Converter` then calls `Validate("Currency Code", "OMS Currency Code")` whenever the OMS value
is nonblank, both on the temporary `VALIDATION` header and on the real PO. That overwrites the correct
vendor-derived local-currency state with nonblank `PHP`, making BC treat it as foreign currency. The current
error occurs at the deliberate pre-insert `TestField("Currency Factor")`, so no real PO is created by this
failed attempt.

## Proposed fix

Let standard `Validate("Buy-from Vendor No.")` remain the authority that initializes Purchase Header currency.
Add one converter-local consistency check that reads `General Ledger Setup`.`LCY Code`, interprets a blank
Purchase Header Currency Code as that LCY, and requires the effective BC currency to equal the OMS currency.
Use the check during temporary prevalidation; do not overwrite Currency Code on the real PO. Keep the existing
nonzero-factor check for every vendor-derived nonblank currency. This rejects a real OMS/vendor mismatch before
insert without hardcoding `PHP`, inventing a factor, or weakening BC exchange-rate validation.

## Regression risk

Low and contained to Draft-to-PO currency validation. A vendor whose configured currency differs from the OMS
order currency will now receive a clear pre-insert mismatch error instead of having the vendor's standard
currency silently overridden. Genuine foreign-currency vendors must still derive a valid factor from standard
Business Central exchange rates for the effective document date.

## Tests required

- **Happy path:** Given OMS currency equal to company LCY, conversion creates and releases a PO with blank Currency Code and Currency Factor zero.
- **Adjacent:** Given a configured foreign currency with an applicable exchange rate, conversion preserves that Currency Code and produces a nonzero factor.
- **Edge case:** Given a foreign currency without an applicable rate, conversion fails on `VALIDATION` before inserting a real PO.

## Skills Evidencing

| Field | Value |
|---|---|
| Skill loaded | bc-al-bug-fix |
| Symptom | Currency Factor is zero on temporary Purchase Header `VALIDATION` |
| Layer | Integration / Logic |
| Root cause | OMS explicit LCY code was written as BC foreign currency |
| Fix applied | Vendor-derived BC currency is retained and checked against the effective OMS currency before PO insertion |
| Diagnosis doc | TBGC_DraftOrderConverter-local-currency-diagnosis.md |
| Tests defined | 3 |

## Verification evidence

- `scripts/Test-DraftOrderCurrency.ps1` failed before the converter change because the vendor/OMS consistency check did not exist, then passed after the fix.
- The existing Draft Order number-series source contract still passes.
- AL compiler 17.0 compiled all 141 project files as `OMSAPI2_1.1.2.16.app` with zero errors.
- Runtime verification remains: publish to `PREPRODTEST`, retry the affected local-currency Draft, and prove one configured foreign-currency Draft plus one mismatch rejection.
