# APL employee attribution — local implementation

23 October 2026, Manila. Sol High implementation under the accepted [[2026-10-23-apl-employee-attribution]] plan. **Implemented locally; final Astra review pending.** No commit/push/deployment/publication, permission grant, setup save or hosted price/receipt mutation in this batch.

## Behavior and security

VMS resolves the applying employee ID/name from the current active database user inside price admission, rather than trusting a browser field or older session name. The immutable identity/command snapshot is stored in existing intentJson and audit details. Approvals use the actual approver; direct Apply/end-date uses its operator. Original requester history is preserved. Names over200 characters, employee IDs over50, blank/control/outer-whitespace values and incomplete identities are rejected before BC writes. An approver name over100 is refused rather than silently truncated into the existing BC approval field.

Both existing BC write calls carry attribution: old-price close and successor insert. Each echoed employee/source/operation is verified before success. Unexpected/missing echo retains the existing uncertainty reservation and no-blind-retry behavior. Completed legacy command replay returns existing evidence without requiring the new contract or a new identity. The request hash has not changed.

The APL API advertises contract1 only when the current company's new attribution setup is enabled for the authenticated BC user's exact security ID. VMS rejects missing/zero contract before a command/first price write. New BC setup is absent/disabled by default and is not automatically populated. Service read and admin setup permission sets are separate and initially unassigned by this package.

AL stores employee name/ID, VMS staff ID, command ID and source in five new internal, non-editable fields. API inputs use separate variables, supplied-field flags and a complete validated snapshot. A local manually bound event subscriber stamps only its exact SystemId/company and intended insert/modify. No SingleInstance context or second attribution-only Modify is used. Bindings expire when the local instance leaves scope, including errors.

Global database insert/modify/rename subscribers first clear old business stamps, including RunTrigger=false paths; the bounded trusted API scope supplies the replacement on that same write. Copied/native/legacy changes therefore fall back to the actual BC account. SystemModifiedBy/At remain platform-owned. The page shows the business Modified By, employee ID, separately labelled BC Modified By, source and operation reference. Existing approval meaning remains unchanged.

This is a trusted assertion from the configured pricing run-as identity. It does not change the existing password-grant pricing connection or solve broad integration permissions. The receipt Undo service and OMS business tables are untouched.

## Optimization and compatibility

- Zero additional BC price-write calls: still one close PATCH and one successor POST, or one end-date PATCH.
- Contract setup is read once on API page opening, not per returned row. Stamping checks the single primary-key setup row and consumes a record-specific local binding.
- Native non-attributed mutations clear five fields without querying employee/setup tables. Existing BC User lookup for display is retained.
- One additional bounded current-employee lookup at admission; existing post-insert ownership recheck is retained for data-reset safety. No cross-row name cache weakens current authority checks.
- No new Azure table/migration: existing command JSON and audit storage hold identity snapshots.
- Date/expiry/approval/series/ETag/idempotency guards and rate limits remain. The source-close and successor calls remain separate remote transactions.
- Old backend requests still follow their existing BC behavior and clear old attribution. New backend will not write against old/unconfigured AL. Release must publish/configure and verify the contract before backend deployment.
- No new hosted1,000-item capacity claim. The existing1,000-item evidence is retained; this change adds bounded identity work per operation.

## Validation

- Red-first regressions reproduced absent contract enforcement, stale session actor names, missing payload stamps and unverified BC echoes before implementation.
- Final backend: **2,553 tests /132 files PASS**. Focused attribution/maintenance/write/history:104 tests PASS.
- Backend build, strict changed-test typecheck, focused lint and diff whitespace checks PASS.
- Real disposable HTTP/SQL fixture: **919 HTTP checks**,30 pricing policy assertions and20 bulk assertions PASS. Positive direct/bulk paths compare current employee with persisted command/audit/BC response; old contract and forged identity are refused before writes. Existing policy, company/role revocation, lost response, audit rollback, cancellation and duplicate protections are exercised. BC is an in-memory transport; zero external BC writes.
- Required disposable SQL security gate PASS with connection_limit6. Two earlier attempts used my overly restrictive connection_limit2 and starved concurrent transaction/nested access queries at the existing5-second timeout. No application timeout/guard was relaxed. Cleanup verified for every run.
- A first broad Vitest run concurrently with AL compilation hit the existing file-parser worker deadline in one test; bounded --maxWorkers=2 passes all tests without changing its production deadline.
- Production **AL1.1.2.29** compiles directly from C:/AL/ALProject3. Seven isolated AL runtime tests compile as a separate app; none are compiled into production. **They have not executed against BC.**
- APL date and OMSAPI2 source-contract scripts PASS. The old Test-ReceiptLineRead.ps1 script rejects the already-existing Undo action; both that script and receipt API are byte-unchanged in this diff. This obsolete read-only-only assertion predates attribution and is not reported as passing.
- Package parity against root1.1.2.28: zero removed pre-existing sources/assets; exactly the APL table, list page and pricing API changed. Five new production AL files and a conditionally excluded test source added.
- Independent local SQL query confirms no VMS_ZapSecurity_Test or VMS_Security_Test_* database remains.

## Artifacts and runtime gate

Production candidate: C:/AL/ALProject3/Systems Integration_Approved Product List_1.1.2.29.app. It is a compiled candidate, **not cleared for publication yet**. User publishes after final review PASS.

Test app: C:/AL/ALProject3/tests/apl-attribution/Systems Integration_VMS APL Attribution Tests_1.0.0.0.app; seven AutoRollback tests cover missing/wrong caller, trusted stamp, Modify(false), copy, error-scope cleanup, ModifyAll/rename and invalid identity. Runtime execution requires a separately approved test-app installation/run/uninstall and verifies that native event/OData behavior matches the source design.

BC changes: table80268 setup, page80269 setup, codeunits80268/80269 guard/scope, permission sets80268/80269, APL table80266 fields30–34 and list80267/API80222. Existing sources/assets are retained. Exact allowed integration user/company configuration and any service grant require fresh read-only identity preflight and separate hosted approval; no guessed security IDs.

Review must examine actual AL binding/event/OData paths, same-write ETag behavior, stale-stamp invalidation, setup/caller authority, old contract rollout, all actual source/test diffs and package/source hashes. BC runtime remains unverified; no security or financial-live clearance is claimed by compilation or synthetic BC transport.

Next: user switches to Astra High for final review. After PASS, obtain exact setup/grant/test approvals; user publishes the app, then verify metadata/runtime before authorized VMS release. Keep successful earlier price/Undo records intact and continue remaining DEMO2 acceptance after this addition.