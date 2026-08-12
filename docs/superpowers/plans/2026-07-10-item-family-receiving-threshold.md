# Item Family Receiving Threshold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve purchase receiving tolerance per LSC Item Family without changing Market List or Draft Order behavior.

**Architecture:** Store the percentage on `LSC Item Family`, resolve it from the purchase line item at validation time, and retain the existing calculation and receiving hooks. Generate stable, collision-free Over-Receipt Codes and never mutate a mismatched shared code.

**Tech Stack:** Microsoft Dynamics 365 Business Central AL, LS Central Item Families

---

### Task 1: Move the setup field

**Files:**
- Modify: `src/ReactBC-main/Purch&Payables/POReceivingThreshold.al`
- Modify: `src/ReactBC-main/TBGC Item Family/TBGC_ItemFamily.TableExt.al`
- Modify: `src/ReactBC-main/TBGC Item Family/TBGC_ItemFamily.PageExt.al`

- [ ] Remove the threshold field and page control from Purchases & Payables Setup.
- [ ] Add the same constrained decimal field to `LSC Item Family`.
- [ ] Add the threshold control to the Item Families page with an explanatory tooltip.

### Task 2: Resolve threshold per purchase-line item

**Files:**
- Modify: `src/ReactBC-main/Purch&Payables/POReceivingThreshold.al`

- [ ] Add one local threshold resolver that loads the Item Family code from Item and the percentage from `LSC Item Family`.
- [ ] Return zero for missing item, blank/missing family, or zero percentage.
- [ ] Replace all three Purchases & Payables Setup threshold reads with the resolver.
- [ ] Keep the existing maximum, confirmation, and blocking logic unchanged.

### Task 3: Make generated Over-Receipt Codes safe

**Files:**
- Modify: `src/ReactBC-main/Purch&Payables/POReceivingThreshold.al`

- [ ] Generate a locale-independent code from the percentage rounded to five decimal places.
- [ ] Reject an existing generated code whose tolerance differs instead of modifying it.
- [ ] Preserve insertion of a missing code with the resolved family percentage.

### Task 4: Verify the integration

**Files:**
- Verify: `app.json`
- Verify: `.vscode/launch.json`
- Verify: all threshold-related AL objects

- [ ] Search for stale Purchases & Payables Setup threshold references; expect none.
- [ ] Search Market List and Draft Order code to confirm no new receiving-threshold dependencies.
- [ ] Compile using the configured AL compiler; expect exit code 0.
- [ ] Inspect `git diff` and confirm only the approved field move, resolver, safe code generation, and design documents changed.

