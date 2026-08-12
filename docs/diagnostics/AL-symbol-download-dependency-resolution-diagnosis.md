# Bug Diagnosis — AL symbol download and cascading compiler errors

**Date:** 2026-08-05
**Severity:** High
**Status:** Diagnosed

## Symptom

VS Code reports many AL errors, and `AL: Download Symbols` does not complete successfully for the `PREPRODTEST` Business Central sandbox.

**Reproducibility:** Always in the current workspace state.

## Layer and category

- **Layer:** Configuration / dependency resolution
- **Category:** Missing or incompatible symbol packages

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | Required Base Application and LS Central packages are missing from `.alpackages` | HIGH | `alc.exe` reports AL1022 for both packages; neither package exists in the cache. |
| 2 | `app.json` contains inconsistent BC/LS metadata | HIGH | The project targets platform 26/runtime 15 but declares BC/LS 28.2 dependencies; LS Central System App is declared with publisher `Microsoft`, while its package manifest says `LS Retail`. |
| 3 | Authentication is preventing symbol download | LOW | AL output explicitly confirms successful authentication to the correct tenant and environment, so authentication is not the current failure point. |

## Confirmed root cause

The editor errors are cascading dependency errors. The current symbol cache cannot satisfy two required packages:

- `Microsoft / Base Application`, compatible with version `28.2.0.0`
- `LS Retail / LS Central`, compatible with version `1.0.0.0`

The installed AL compiler reproduces these as `AL1022`. It also reports `AL1076` because dependency ID `2a0547fa-f60f-401d-b1fe-c7c4be8fb230` is declared under publisher `Microsoft`, but the downloaded package identifies its publisher as `LS Retail`.

The manifest is internally inconsistent: `platform` is `26.0.0.0` and `runtime` is `15.0`, while several direct dependencies are version `28.2`. The cached Microsoft `Application` package is platform 28/runtime 17 and propagates `System Application`, `Business Foundation`, and `Base Application` dependencies. Until the project manifest, target environment, and cached packages agree on one version line, symbol resolution cannot complete and source references that depend on those packages appear as many separate errors.

AL output shows successful authentication and sends all `/dev/packages` requests, but the attempts recorded today never log a completion or response. This rules out a simple sign-in failure; the immediate compile blockers remain the two absent packages and inconsistent dependency metadata.

## Proposed fix

Align `app.json` with the actual `PREPRODTEST` application/runtime versions, correct the LS Central System App publisher, and reduce direct Microsoft dependencies to the supported aggregate application dependency where appropriate. Then refresh `.alpackages` and ensure the exact Base Application and LS Central symbol packages installed in `PREPRODTEST` are available. If LS Central still cannot be downloaded after the manifest is aligned, the environment administrator or LS partner must verify that the matching LS Central app is installed and its symbols are exposed to the development endpoint.

## Regression risk

Changing dependency baselines can expose genuine API changes between BC/LS 26 and 28.2 after symbols load. The change must be limited to manifest metadata first; source changes should only address real compiler errors that remain afterward.

## Tests required

- **Happy path:** Run `AL: Download Symbols`; all declared and transitive packages download, and an `alc.exe` build passes dependency resolution.
- **Adjacent:** Confirm the extension still targets the intended `PREPRODTEST` tenant/environment and can publish there.
- **Edge case:** Confirm LS Central objects used by the extension resolve against the exact installed LS Central 28.2 package without publisher/version warnings.

## Skills Evidencing

| Field | Value |
|---|---|
| Skill loaded | bc-al-bug-fix |
| Symptom | Many AL errors and symbol download does not complete |
| Layer | Configuration / dependency resolution |
| Root cause | Missing/incompatible symbol packages and inconsistent manifest metadata |
| Fix applied | None; diagnosis only, pending confirmation |
| Diagnosis doc | `docs/diagnostics/AL-symbol-download-dependency-resolution-diagnosis.md` |
| Tests defined | 3 |
