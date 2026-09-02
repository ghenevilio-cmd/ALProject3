# OMSAPI2

This folder contains only the Business Central additions required by the standalone
Ordering Management System. Existing VMS APIs and the custom BC Draft Order tables
are outside this integration.

## Number ownership

- OMS assigns `OMS PO Ref. No.` from the company-specific OMS PO number-series setup.
- Business Central assigns the official Purchase Order `No.` from its standard
  purchase-order number series when the queued OMS order is created.
- OMS stores the returned BC `SystemId`, official PO number, and ETag and shows the
  official number on the submitted OMS order. OMS never generates a BC PO number.
- OMS assigns `OMS Receiving Ref. No.` from its separate company-specific receiving
  number-series setup after receiving approval.
- Business Central assigns the official posted purchase-receipt number through its
  standard posting setup.

## Additional Business Central fields

| Standard table | Added field | Purpose |
|---|---|---|
| Purchase Header | `OMS PO Ref. No.` (`Code[11]`) | Links the standard BC PO to its OMS order. |
| Purchase Header | `OMS Receiving Ref. No.` (`Code[11]`) | Carries the approved OMS receiving reference during standard receipt posting; not shown as an editable user field. |
| Purchase Header | `OMS PO Payload Hash` (`Code[64]`) | Detects a changed retry for an existing OMS PO reference. |
| Purchase Header | `OMS Receiving Payload Hash` (`Code[64]`) | Detects a changed retry for an existing OMS receiving reference. |
| Purch. Rcpt. Header | `OMS PO Ref. No.` (`Code[11]`) | Preserves the originating OMS order reference. |
| Purch. Rcpt. Header | `OMS Receiving Ref. No.` (`Code[11]`) | Identifies the individual OMS receiving transaction, including partial receipts. |
| Purch. Rcpt. Header | `OMS PO Payload Hash` and `OMS Receiving Payload Hash` (`Code[64]`) | Supports safe reconciliation without displaying internal hashes to users. |

Both posted-receipt fields are read-only. Source and posted fields use matching field
IDs so the standard `Purch.-Post` `TransferFields` path can propagate them without a
redundant subscriber, subject to the PREPRODTEST posting proof.

## Standard process boundary

1. OMS freezes the completed market-list draft and commits an outbox message.
2. OMSAPI2 creates normal Purchase Header and Purchase Line records with standard
   `Validate` calls and uses `Release Purchase Document`.
3. OMS records the BC SystemId, official PO number, and ETag returned by BC.
4. OMS receiving approval unlocks quantity entry.
5. OMSAPI2 sets the approved quantities and posts receipt-only through `Purch.-Post`.
6. OMS records the official posted purchase-receipt identity returned by BC.

## Read-only reference APIs

OMSAPI2 also exposes company-scoped, read-only API pages for concepts, stores, zoning, and approved products.
The store `code` is its Business Central Location Code; OMS sends the selected store's code when it creates the
standard Purchase Header. These APIs do not create or modify Business Central master data.

Receiving commands target the exact Purchase Order `SystemId` returned by Business Central. Matching retries
resume or return the stored result, changed payload hashes conflict, and concurrent post actions are serialized
on the receipt-command row.

There is no PO approval, parallel BC purchasing workflow, direct write to posted
tables, or reuse of `TBGC Draft Order Header` / `TBGC Draft Order Line`.
