# Receipt-line read connector release candidate

Prepared locally: Approved Product List1.1.2.26, NOT published. Use only artifacts/receipt-line-1.1.2.26/Systems Integration_Approved Product List_1.1.2.26.app after final review and exact hosted publication approval. Never publish the dirty root project as this candidate.

The build script pins the prior1.1.2.25 artifact, preserves148 source files and shipped JS/CSS/report layouts, adds only read page80261 + read permission set80261, and verifies compiled package contents. No financial action or new BC business table. release-manifest.json freezes the exact binary/per-source hashes. Compiler embeds build timestamps, so a rebuild changes the binary hash and requires renewed verification.

Before publication verify installed app identity/version matches the baseline. After approved publication assign only OMS2 RCPT LINE READ to the intended service application under exact permission approval, verify positive exact receipt reads, rejected missing/range filters, complete IDs/quantities/version fields and denied mutations. No SUPER assignment, standard Undo execution or live mutation fixture is approved by this document.

See VMS [[2026-10-18 FLOW DEMO 2 E1 Implementation]] for dependent application candidate, migration and security limits. Financial Undo remains held for F concurrency/reconciliation/runtime proof.
