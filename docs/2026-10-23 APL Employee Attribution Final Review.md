# APL employee attribution — final Astra source review

23 October 2026, Manila. User confirmed Astra High. **PASS for source review and controlled PREPRODTEST publication. VMS backend release and attributed financial execution remain held for BC runtime verification.**

## Scope and evidence

Reviewed the actual VMS write/admission/audit diff, all callers (single internal, bulk direct, individual and selected approval, vendor approval, end-date), strict request schema, current staff/company permissions, seven new/changed source-test files, eight production AL files, test application, manifests and saved local SQL/HTTP evidence. No application code or tests changed during this review. All 46 frozen candidate records matched before review.

Fresh independent checks: 104 tests across attribution, maintenance, write-client and history passed; git diff whitespace check passed. Package contents were independently compared to 1.1.2.28 and current ALProject3: zero removed sources/assets, only three existing AL files changed, no source mismatches and no compiled test codeunit in production. Earlier evidence remains 2,553 backend tests, 919 local HTTP checks, SQL security gate, build/types/lint and both AL compilations; it was inspected, not represented as a new full rerun.

Production package:
C:/AL/ALProject3/Systems Integration_Approved Product List_1.1.2.29.app

SHA-256:
8604dadfdd46f810c8734e67b2f34c65085d8b0e01d6877d2fa636426ae13689

## Security and audit findings

No blocking source finding identified.

- VMS maintenance and approval routes retain strict input schemas and company-specific backend permissions. Browser-supplied employee attribution is rejected. Current active database employee identity, not session display text, supplies the snapshot.
- Command actor and intent plus attempt, success/approval and uncertain/failure audit details use the same identity/command snapshot. Original requester evidence remains separate. Historical completed command replay does not recapture a renamed employee or repeat BC writes.
- BC contract capability is zero unless the current company's setup is enabled for the exact authenticated BC user security ID and readable by that user. The write path rechecks this authority. Setup and service permission sets are separate; this package assigns neither.
- API identity fields are variables with explicit supplied-field flags. A complete bounded identity is required; table fields are internal/non-editable. The manual subscriber is local, single-use and bound to SystemId, operation and company. It cannot intentionally survive its local scope.
- Native/legacy insert, modify and rename paths clear the business stamp in before-events. Price-table validation remains invoked on attributed API writes. No second attribution-only Modify or new financial retry is added.
- BC SystemModifiedBy/At remain the real technical audit. VMS's employee attribution is a trusted integration assertion, not independent BC authentication of that employee.
- Existing ETags, source/successor verification, price-series reservation, no-self-approval, policy/date guards and uncertain-result handling remain. Missing/wrong attribution echo cannot be marked successful. The two remote price mutations remain separate transactions.

API review: maintenance POST and approval/bulk callers retain authenticated staff/company/operation checks; status/preview retain scoped reads. The BC APL POST/PATCH accepts employee assertion only through the configured caller/company, while legacy requests keep their existing behavior. No new browser endpoint, cross-database access, broad permission grant or arbitrary actor input was introduced.

## Optimization and compatibility

No added BC write calls or network retries. VMS adds one bounded employee lookup inside admission. AL capability uses one singleton read on page opening, not per returned APL row; stamp verification uses bounded singleton checks. Existing list-page User lookup is retained.

Global APL database subscribers can cause native bulk modifications to use per-record event processing. No affected in-repository APL ModifyAll production writer was found, but external extensions/job throughput has not been benchmarked. This is a limitation, not evidence of a measured regression.

Old backend requests remain compatible with the new default-disabled AL package. New VMS backend refuses old/unconfigured AL before the first price write, so do not deploy VMS before successful runtime/capability verification for the companies that use pricing. No Azure SQL migration is required.

## AL review categories

Internal per-tenant extension; AppSource submission requirements are not a release target.

| Category | Result |
|---|---|
| Naming/structure | New object IDs are within the declared production range; separate test ID is excluded from compiled production objects. No new environment/user IDs are hardcoded. |
| Performance | Bounded setup/identity work; no extra price writes. Native bulk-event overhead is an unmeasured limitation above. |
| Extensibility/transactions | Local bound subscriber and same-write stamp; no Commit or long-lived global stamping context. No optional bypass event is recommended for an authorization guard. |
| SaaS/security | No file/network/secret handling added in AL. Exact caller/company and table permissions protect attribution/setup; native system fields are preserved. |
| AppSource | Not assessed as an AppSource submission. Existing manifest marketing/localization metadata is outside this focused tenant release. |

Skills used: bc-al-code-reviewer, security-api-review, framework implementation-review. No stylistic refactor or speculative finding added.

## Required runtime gates after publication

The seven AL tests are compiled, **not executed**. Their temporary records do not prove real OData or persisted system-audit behavior. Before VMS release/financial clearance:

1. Verify installed 1.1.2.29 and metadata against the reviewed package; leave attribution disabled until the exact integration identity and company are verified.
2. Obtain approval for installation/run/uninstallation of only the reviewed temporary test app. Run the seven tests and retain their results.
3. Verify native invalidation using fresh readback, especially after ModifyAll/rename; inspecting only the existing in-memory record is insufficient. The current rename test does not reload the renamed row, so do not report persisted rename behavior as proved by it.
4. Verify actual API POST/PATCH field flags, same-write response and persisted attribution, ETag refusal, missing/partial assertion, wrong caller/company and fallback. Use only separately approved fixtures; no prior successful live price or Undo operation may be replayed for this.
5. Verify current ordinary BC access and unchanged old-backend behavior. Confirm the exact service/user grant and enabled-company setup only under separately approved scope. No SUPER grant.
6. After capability and runtime checks pass, release reviewed VMS under the standing release authorization and arrange any fresh financial test with exact records/values/dates/actors.

This review does not authorize an attributed business write, test-app installation or setup/grant changes. User publishes the production AL package personally. The old unchanged receipt-read-only source script remains obsolete for the existing Undo action; it was not counted as passing.

## Platform references

- [BC system fields](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields): preserve platform-owned technical audit.
- [Manual subscription lifetime](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-bindsubscription-method): a local codeunit binding is removed when the instance leaves scope.
- [Custom API patterns](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-develop-custom-api): page variables and controlled record mutation; actual endpoint behavior still needs runtime verification.
- [Database event order](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types) and [Rename](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method): validate persisted native-change behavior rather than inferring it from compilation.

## Continuation

Ready for the user to publish the exact AL1.1.2.29 package to PREPRODTEST. Source/test/package files remain unchanged. Save this review and update [[DEMO_2_ENHANCEMENT_SUMMARY]]; preserve completed price/Undo history and return to the remaining DEMO2 acceptance matrix after this addition's release gates.

