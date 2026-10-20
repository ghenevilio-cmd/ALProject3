# Build and publish from ALProject3

AL source of truth: `C:/AL/ALProject3`. Root version: **1.1.2.28**. All153 application sources and7 shipped assets match the reviewed correction. No source was replaced or removed.

Open this root folder in VS Code and run **AL: Package**. The production output is `Systems Integration_Approved Product List_1.1.2.28.app` in this folder. Use the root launch configuration targeting PREPRODTEST when publishing; preserve any existing credentials privately. Do not publish the separate test app as production.

`tests/receipt-concept` is the separate test project. Its symbol `OMS_RECEIPT_CONCEPT_TESTS` includes codeunit80351 only in that project. Keep this symbol absent from root app.json; production object IDs remain80201..80300. Both builds pass. The test cache is under its ignored `.alpackages` directory and uses the root-built production dependency. Seven test procedures compile; they have not run in BC.

Run `python scripts/verify_direct_receipt_concept_package.py` before publishing the current28 release. It compares application/compiled payload/assets to the reviewed clean candidate, excludes the test object from production, and checks the separate seven-test app. Timestamp/build origin, generated navigation GUID/order and ZIP compression metadata may differ; application content may not. The extra source file is conditionally excluded, not a deployed test object. Nine AL1025 license-text warnings are recorded; no compiler error remains.

The user published the root-built28 on20 October. Installed package ID matches the NAVX package identity in the verified root file. BC read-only evidence confirms both affected receipt lines return location1991/conceptDENNYS/raw dimension1991/version2. The exact published root artifact is retained under `artifacts/receipt-concept-1.1.2.28/published-root/`. Do not overwrite prior frozen candidate artifacts.

No financial Undo was executed. Existing VMS cases1/2 still require separate exact repair approval; corrected connector publication does not rewrite them. See [[ALProject3-Direct-Build-Final-Review-2026-10-20]].
