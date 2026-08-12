# Bug Diagnosis - Market List Receiving Lazy Load

Date: 2026-07-03
Severity: Medium
Status: Diagnosed

## Symptom
Market List Receiving still loads slowly, shows "Scroll to load more purchase orders", and does not fetch the next page when scrolling.

## Layer and category
- Layer: UI / Integration / Performance
- Category: Page loads slowly; action/trigger does not execute as expected.

## Hypotheses
| Priority | Root cause | Probability | Evidence |
|---|---|---|---|
| 1 | RefreshReceivingWorkspace still fetches orders during page initialization | High | Page trigger calls loadReceivingOrders(GetReceivingOrdersPageJson(...)) on ControlAddInReady. |
| 2 | Backend page payload loops through all filtered purchase orders for status counts | High | GetReceivingOrdersPagePayload continues until PurchHeader.Next() = 0. |
| 3 | React paging request is blocked or unreliable in the embedded browser | Medium | UI only displays a scroll prompt; no clickable fallback exists. |

## Confirmed root cause
The previous implementation paged the JSON returned to React, but it still queried and calculated metrics across the full filtered PO set in AL. The page also fetched immediately on initialization. This means it was not true lazy loading.

## Proposed fix
Initialize only the context on page open, fetch the first 15 only when the user applies a filter/search/location/status action, fetch one extra record to determine hasMore, and stop the AL loop as soon as the requested page is known. Add a clickable load-more fallback in the React grid.

## Regression risk
Snapshot status counts will no longer represent all matching records unless a separate aggregate endpoint is added later. This is intentional for speed and true lazy loading.

## Tests required
- Happy path: Open Market List Receiving; no PO data is fetched until a filter is applied.
- Adjacent: Apply a filter; first 15 POs load and Receive PO still opens the selected PO.
- Edge: Scroll or click load more; next 15 POs append without duplicating existing rows.
