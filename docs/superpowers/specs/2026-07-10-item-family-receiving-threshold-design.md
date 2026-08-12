# Item Family Receiving Threshold Design

## Goal

Move the purchase over-receipt threshold from Purchases & Payables Setup to LSC Item Family while preserving the existing Market List, Draft Order, purchase-order receiving, actual receipt date, and posting behavior.

## Architecture

Add `TBGC PO Rcvg Threshold %` to the existing `LSC Item Family` table extension and expose it on the existing Item Families page extension. Remove the same field and control from Purchases & Payables Setup.

When validating `Purchase Line."Qty. to Receive"`, resolve the threshold from the line item's `Item."LSC Item Family Code"` and then the corresponding `LSC Item Family` record. A missing item, blank/missing family, or zero threshold returns zero, meaning the extension does not enable custom over-receipt and Business Central's standard validation remains authoritative.

## Preserved Behavior

- Threshold maximum remains `Original Ordered Quantity * (1 + Threshold / 100)`.
- Receipts within the threshold still receive user confirmation when a GUI is available.
- Receipts above the threshold remain blocked.
- Original ordered quantity capture remains unchanged.
- Actual receipt date validation and clearing remain unchanged.
- Market List and Draft Order creation/conversion remain unchanged; they do not calculate the receiving threshold.

## Over-Receipt Code Safety

Generate an unambiguous code from the threshold at a fixed five-decimal scale so values such as `1.5` and `15` cannot share a code. Never modify an existing generated code to a different tolerance. If a generated code already exists with an unexpected tolerance, stop with an error instead of silently changing shared master data.

## Verification

- Confirm all runtime threshold reads use Item Family and no reads remain against Purchases & Payables Setup.
- Confirm Draft Order and Market List code has no dependency on the removed setup field.
- Compile the AL extension with the project's configured AL compiler.
- Review the final diff for unrelated changes.

