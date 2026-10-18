# DEMO 2 E0 — Receipt-line read foundation

Status: implemented locally in user-confirmed Sol High; final Astra review pending. No deployment, AL publication, permission grant, migration or BC financial write.

## Scope and contract

User approved the minimal connector in `C:/AL/ALProject3/src/OMSAPI2`. Read-only installed PREPRODTEST metadata returned 200 for standard v2.0, custom omsapi2/v1.0 and ODataV4. Standard purchaseReceiptLine exists but lacks the complete invoiced/base/correction contract; the custom API has headers only. No matching Undo action was found in those inspected metadata surfaces. See [[flow-demo2-e0-metadata-2026-10-18]]. This is bounded discovery, not proof about every installed extension.

Added page80261, postedReceiptLines, requiring exact orderNumber/orderLineNumber filters and returning stable receipt/line IDs, parent identity, invoice/base/UOM quantities, correction/version and linked-document indicators. Dedicated permission set80261 OMS2 RCPT LINE READ grants only receipt header/line reads and page execution. It is not assigned or published. Missing parents fail instead of returning an empty identity.

VMS GET /po/receipt-lines (both existing API aliases) requires current staff orders.view and selected-company authority. It reads fresh BC data, caps results at500 using existing read budgets/cancellation, validates exact ownership and quantities, and rechecks session/company permission and mapping before returning no-store data. Invoiced, corrected and unsupported lines are distinct. Unknown/malformed evidence fails closed. UNINVOICED is a data classification, not permission to dispute or a promise that Undo succeeds. No mutation route exists.

This read endpoint uses existing company-scoped PO-view authority. Future dispute and Undo writes need their own explicit action permissions and current company/store scope. No dispute schema, SLA, OMS read-through, approval/outbox or standard Undo adapter is implemented in E0.

## Checks

- Full VMS backend: 2,162 tests passed in107 files; new contract/router tests66.
- Production backend build and strict new-test typecheck passed.
- Shared authorization inventory includes new nested router; generated inventory214 endpoints.
- AL full-project compilation passed; existing AL1025 warnings concern unrelated React node_modules license files.
- AL static read-boundary/permission assertions passed. These do not establish runtime filter or service permission behavior.
- No database fixture/migration required or executed for this read-only batch. Frontend unchanged.

## Release and next gates

Final Astra review must inspect actual source/test/AL diff and frozen manifest. No application commit/push/deploy before PASS. AL publication and any service permission assignment require exact approval and hosted read-only validation. Do not publish the temporary full-project compile artifact: ALProject3 contains unrelated existing changes and no release version was prepared.

The financial action remains held until installed standard Undo call graph, concurrent invoicing, exact-line filtering, supported side effects and lost-response reconciliation are proved. Do not infer safe financial execution from this read endpoint or compilation. Preserve the approved per-line zero-invoice, no-over-reversal and no-self-approval rules.

Excluded: existing VMS handoff/status changes and frontend build-info/raw local fixture reports; unrelated AL changes; original Desktop OMS files except the requested summary copy. Broader security coverage remains incomplete.
