# ALProject3 direct-build alignment review

20 October 2026 — Astra High. **Application content matches; direct build needs two configuration/test-isolation corrections.**

## Corrected finding
The earlier suggestion that the current root contains different/unreviewed application source was too broad. A fresh byte comparison proves all153 src AL files and all7 shipped control-addin/layout assets exactly match the reviewed clean1.1.2.28 candidate. There are no missing, extra or changed src AL files. Dependencies, platform/application/runtime, identity and resource exposure policy match; root manifest remains1.1.2.26. Existing VS Code cache differences are editor state, not application code.

## Reproduced direct-build blocker
Compiler18.1.43.24897 invoked directly against C:/AL/ALProject3 discovers154 AL files:153 application files plus tests/receipt-concept/ReceiptConceptTests.Codeunit.al. It fails AL0297 because test codeunit80351 is outside production range80201..80300. A nested app.json alone does not exclude it from this compiler invocation. Do not widen the production range or delete the tests to hide the problem.

## Smallest correction, in ALProject3 only
1. Change only root app.json version from1.1.2.26 to1.1.2.28. Preserve identity, dependencies, security policy and object ranges.
2. Wrap the existing test codeunit with a dedicated AL conditional compilation symbol, defined only in tests/receipt-concept/app.json. Production leaves it undefined; the separate test build defines it. Preserve all seven test procedures and their behavior. This keeps both projects within the user-selected folder.
3. Build directly from root into its normal ignored .app output. Inspect the compiled object inventory: no test codeunit80351, all153 reviewed application sources/objects and7 runtime assets preserved. Compare semantic manifests/compiled object definitions with the reviewed clean candidate, accounting only for nonfunctional build metadata and excluded test source.
4. Compile the separate test app against the direct production output; confirm all7 test methods are present. Compilation does not establish BC runtime acceptance.
5. Record resulting hashes and source parity, obtain focused final Astra review, then use the root-built package for user publication. Update normal build instructions; retain previous clean artifacts as frozen evidence. No source replacement, deletion, git reset, publication or hosted data change is included.

Microsoft documents conditional compilation and app.json preprocessorSymbols: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/directives/devenv-directives-in-al . The local compiler failure, not a documentation assumption, establishes the nested-project problem here.

## Status / boundaries
No application or configuration file was changed during this review. User requires all future edits in ALProject3. Existing153 source files already include all reviewed fixes. Exact BC publication, backend release and separately approved existing-case repair remain pending. No financial Undo was performed. The candidate clean artifact remains unchanged.
