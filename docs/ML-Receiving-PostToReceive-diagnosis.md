# Diagnosis — "Purchase Header … not up-to-date" on Post to Receive

**Date:** 2026-07-27
**Error time stamp:** 2026-07-27T07:35:01Z
**Document:** Purchase Order `POR10029640`
**App:** Approved Product List 1.1.2.4 (Systems Integration)
**Platform:** BC 27.2 (Base Application 27.2.42879.50528)

---

## 1. Symptom (as reported)

> The changes to the Purchase Header record cannot be saved because some information on the page
> is not up-to-date. Close the page, reopen it, and try again.

Raised while posting a receipt from the Market List Receiving workspace:

```
Page 80282 "Market List Receiving"  → ReceivingUI - OpenPurchaseOrder
  → OpenReceivingDocumentAndRefresh
    → CU 80280 "TBGC Receiving Mgt".OpenReceivingDocument
      → OpenMarketListPurchaseOrder            (PAGE.RunModal Purchase Order)
        → PageExt 80287 "TBGC Post To Receive" OnAction
          → CU 90 "Purch.-Post" .OnRun → RunWithCheck → FinalizePosting  ← FAILS
```

## 2. Layer and category

| | |
|---|---|
| **Layer** | Integration (posting) + UI (page/record binding) |
| **Category** | Record concurrency — stale row version (optimistic concurrency conflict) |

This is **not** a validation error, a permission error, or a data error. It is the AL runtime's
optimistic-concurrency check firing on `Modify`: the record instance being written carries an
older row version than the row currently in the database.

## 3. The failing statement — confirmed exactly

The stack line numbers were resolved against the actual Base Application source
(`src/Purchases/Posting/PurchPost.Codeunit.al`). AL numbers stack lines from the line **after** the
procedure/trigger declaration; all three frames match exactly:

| Stack frame | Resolves to | Statement |
|---|---|---|
| `Post To Receive - OnAction` line 14 | `MarketListReceiving_SystemFields_Ext.al:67` | `PurchPost.Run(PurchHeader);` |
| `RunWithCheck` line 147 | `PurchPost.Codeunit.al:258` | `FinalizePosting(PurchHeader, TempDropShptPostBuffer, EverythingInvoiced);` |
| `FinalizePosting` line 12 | `PurchPost.Codeunit.al:3098` | **`PurchHeader.Modify();`** |

Line 3098 sits in the branch for *Order + not everything invoiced* — i.e. exactly the
receive-only posting this action performs (`Receive := true; Invoice := false`).

So: the very first write-back of the Purchase Header at the end of posting is rejected because
the record instance Purch.-Post is holding is stale.

## 4. Why Purch.-Post cannot recover from this

`Purch.-Post` deliberately preserves whatever record snapshot the caller handed it
(`PurchPost.Codeunit.al:3571-3579`):

```al
local procedure GetPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
var
    PurchaseHeaderCopy: Record "Purchase Header";
begin
    PurchaseHeaderCopy := PurchaseHeader;
    PurchaseHeader.ReadIsolation := IsolationLevel::ReadCommitted;
    PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
    PurchaseHeader := PurchaseHeaderCopy;   // ← caller's snapshot restored, row version included
end;
```

It re-reads the row (to take the read lock) and then **overwrites the fresh read with the
caller's copy**, so the caller's row version is what the whole posting run uses. Purch.-Post
then copies that into its working instance at `:159` (`PurchHeader := PurchaseHeader2;`).

**Consequence:** the record passed into `Purch.-Post` must be current *and must remain the only
live handle on that row for the duration of the run.* Purch.-Post will never self-heal a stale
version; it will simply fail at the first `Modify()`.

## 5. Root cause

**The custom `TBGC Post To Receive` action posts a second, independent record instance of a row
that the open Purchase Order page is simultaneously bound to, and never resynchronises the page.**

`MarketListReceiving_SystemFields_Ext.al:53-70`:

```al
trigger OnAction()
begin
    if not Confirm(PostReceiptQst, false, Rec."No.") then exit;

    PurchHeader.Get(Rec."Document Type", Rec."No.");   // ← instance B, separate from page's Rec
    POReceivingThresholdMgt.ValidatePurchaseOrderActualReceiptDates(PurchHeader);
    PurchHeader.Receive := true;
    PurchHeader.Invoice := false;
    PurchPost.Run(PurchHeader);                        // ← posts instance B
    POReceivingThresholdMgt.ClearActualReceiptDatesAfterReceive(PurchHeader);
    CurrPage.Close();
end;
```

There are now **two live instances of `POR10029640`** in the session: the page's `Rec` (instance A,
read when the page opened) and `PurchHeader` (instance B). Neither is told about the other's
writes. Whichever one writes second fails — and because the message is emitted from a UI session
with a page bound to that row, the platform words it as *"some information on the page is not
up-to-date."*

**Base BC never does this.** Page 50 "Purchase Order" posts `Rec` itself
(`PurchaseOrder.Page.al:2554-2578`):

```al
local procedure PostDocument(PostingCodeunitID: Integer; Navigate: Enum "Navigate After Posting")
begin
    LinesInstructionMgt.PurchaseCheckAllLinesHaveQuantityAssigned(Rec);
    Rec.SendToPosting(PostingCodeunitID);   // ← posts the PAGE's record
    ...
    CurrPage.Update(false);                 // ← resyncs the page afterwards
```

and `PurchaseHeader.SendToPosting` (`PurchaseHeader.Table.al:5152-5176`) does the
`Commit()` → `CODEUNIT.Run(PostingCodeunitID, Rec)` → error-handling contract. One instance,
one row version, page resynced. The custom action reproduces none of that.

### Contributing factors found in the same flow

**(a) The page is opened on a record that has already been written and never re-read.**
`TBGC_Receiving_Mgt.Codeunit.al:274-287`:

```al
if not ReadOnly then begin
    RefreshMarketListPostingDate(PurchHeader);    // PurchHeader.Modify(false)
    ResetQtyToReceiveForMarketList(PurchHeader);  // rewrites every line
    Commit();
end;
MarketListReceivingContext.SetPurchaseOrderNo(PurchHeader."No.", ReadOnly);
PAGE.RunModal(Page::"Purchase Order", PurchHeader);   // ← stale in-memory header handed to the page
```

There is no `PurchHeader.Get(...)` between the writes and `RunModal`, so the page starts from an
in-memory snapshot rather than a guaranteed-fresh read.

**(b) Extra `Modify(false)` writes on the header from release subscribers.** Three separate
subscribers on `Release Purchase Document.OnAfterReleasePurchaseDoc` each write the header:

- `TBGC_PurchaseReleaseTracking.Codeunit.al:17` — `PurchaseHeader.Modify(false)`
- `TBGC_Ordering Status Mgt` (Systems Integration Customizations) `:139` — `PurchaseHeader.Modify(false)`
- LS Central `Retail Purchase Order Ext.:383` — `SetReleasedQuantity`

These are on the shared `var` instance so they are safe *inside* the release call, but they mean
the header row version moves more often than base expects, widening the window in (a).

**(c) `Modify(false)` bypasses the header's OnModify trigger.** `RefreshMarketListPostingDate`
assigns `"Posting Date"` directly and saves with `Modify(false)`, so the lines' posting-date
dependent fields are never updated. Separate correctness issue; worth fixing in the same pass.

### What I could not determine from source alone

I could not identify *which* interleaved write bumped the row version in this specific run.
I checked and ruled out, as second-instance header writers during posting: this extension
(no Purchase Header writes outside the release subscriber), `Purchase Line` (base table never
modifies the header), `Over-Receipt Mgt.`, and the `Purch.-Post` subscribers in Standard
Customizations / Systems Integration Customizations / LS Central. That leaves the page's own
`Rec` (instance A) as the most likely writer, plus runtime-only possibilities I cannot observe
statically — the same PO open in a second tab/session, or a Job Queue / replication task touching
it. The design defect in §5 is what makes any of these fatal instead of harmless.

## 6. Proposed fix (description — no code written yet)

1. **Post the page's own record, via the standard contract.** Replace
   `PurchHeader.Get(...)` + `PurchPost.Run(PurchHeader)` with `Rec.Receive := true;
   Rec.Invoice := false;` + `Rec.SendToPosting(CODEUNIT::"Purch.-Post")`, preceded by
   `CurrPage.Update(true)` so pending subform edits are flushed and `Rec` is current.
   This collapses the two instances into one and adopts BC's own commit/error-handling path.

2. **Resync instead of blind-closing.** Replace the unconditional `CurrPage.Close()` with the
   base pattern: `CurrPage.Update(false)`, then close only once posting has succeeded.
   Today, if posting fails, the page is left holding a stale `Rec`, which is precisely the state
   the error message is telling the user to escape.

3. **Re-read the header immediately before `PAGE.RunModal`** in
   `TBGC Receiving Mgt.OpenMarketListPurchaseOrder`, after the `Commit()`, so the page always
   opens on a guaranteed-fresh row version.

4. **Run `ClearActualReceiptDatesAfterReceive` only when posting succeeded**, and against a
   re-read record — currently it runs unconditionally on the same stale instance right after
   `PurchPost.Run`.

5. *(Separate, lower priority)* Change `RefreshMarketListPostingDate` to
   `Validate("Posting Date", WorkDate())` + `Modify(true)`.

Items 1–4 address the reported error. Item 5 is a correctness fix found along the way.

## 7. Regression risk

| Risk | Note |
|---|---|
| `SendToPosting` calls `Commit()` and checks `IsApprovedForPosting()` | If these POs go through approval, behaviour changes from "posts regardless" to "blocked until approved". Needs confirming against the business rule. |
| `SendToPosting` returns a Boolean instead of throwing | The action must branch on the result rather than assume success. |
| `CurrPage.Update(true)` fires `OnModifyRecord` | PageExt 80287's `OnModifyRecord` raises `MarketListHeaderEditErr` in receiving mode. Must use `CurrPage.Update(false)` for the header, or gate the trigger, or the flush itself will error. **This is the main implementation hazard.** |
| Closing later than today | The Market List workspace refresh (`RefreshReceivingWorkspace`) sequencing may need adjusting. |

## 8. Tests to define after the fix

1. **Happy path** — Given a Released PO in Market List Receiving with Qty. to Receive and Actual
   Receipt Date set on all item lines, When Post to Receive is clicked, Then the receipt posts,
   the page closes, and the workspace shows the order as Partial or Fully Received.
2. **Adjacent (must not change)** — Given a PO opened from the normal Purchase Order list (not
   Market List), When posted with the standard Post action, Then behaviour is unchanged.
3. **Adjacent (must not change)** — Given a Fully Received PO opened read-only from Market List,
   Then Post to Receive stays hidden and the page stays non-editable.
4. **Edge — the reported failure** — Given a PO opened from Market List, When Qty. to Receive is
   edited on the last subform line and Post to Receive is clicked immediately without leaving the
   line, Then posting succeeds with no concurrency error.
5. **Edge — failed posting** — Given a line missing its Actual Receipt Date, When Post to Receive
   is clicked, Then the validation error is shown, the page stays open, **and a second attempt
   after correcting the date succeeds** (today the second attempt is the likeliest way to hit
   the stale-record error).
