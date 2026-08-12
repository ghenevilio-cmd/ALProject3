pageextension 80287 "ML Receiving SysInfo Ext" extends "Purchase Order"
{
    layout
    {
        addafter("Order Date")
        {
            field("TBGC Draft Order No."; Rec."TBGC Draft Order No.")
            {
                ApplicationArea = All;
                Caption = 'Draft Order No.';
                Editable = false;
                ToolTip = 'Specifies the source draft order number that created this purchase order.';
            }
        }
        addafter("Expected Receipt Date")
        {
            field("TBGC Original Created By"; Rec."TBGC Original Created By")
            {
                ApplicationArea = All;
                Caption = 'Original CREATED BY';
                Editable = false;
                ToolTip = 'Specifies the user ID from the source draft order that originally created this purchase order.';
            }
            field("System Modified By"; ModifiedByUserName)
            {
                ApplicationArea = All;
                Caption = 'System Modified By';
                Editable = false;
                ToolTip = 'Specifies the user who last modified this purchase order record.';
            }
            field("System Modified At"; Rec.SystemModifiedAt)
            {
                ApplicationArea = All;
                Caption = 'System Modified At';
                Editable = false;
                ToolTip = 'Specifies the date and time when this purchase order record was last modified.';
            }
        }
    }

    actions
    {
        addfirst(Processing)
        {
            action("TBGC Post To Receive")
            {
                ApplicationArea = Suite;
                Caption = 'Post to Receive';
                Image = PostOrder;
                Visible = MarketListReceivingMode and not MarketListReadOnlyMode;
                ToolTip = 'Posts the purchase order receipt only.';

                trigger OnAction()
                var
                    POReceivingThresholdMgt: Codeunit "TBGC PO Rcvg Threshold Mgt";
                    PostReceiptQst: Label 'Do you want to post the receipt for purchase order %1?';
                begin
                    if not Confirm(PostReceiptQst, false, Rec."No.") then
                        exit;

                    // Post the page's own record, as base page 50 does. Purch.-Post has to modify
                    // the Purchase Header to finalise; doing that through a second record instance
                    // while this page is bound to the same row fails the page concurrency check.
                    POReceivingThresholdMgt.ValidatePurchaseOrderActualReceiptDates(Rec);
                    Rec.Receive := true;
                    Rec.Invoice := false;

                    // PostingInProgress lets the posting engine write the header. OnModifyRecord
                    // still blocks interactive header edits, which is what that guard is for.
                    PostingInProgress := true;
                    ClearLastError();
                    if not Rec.SendToPosting(CODEUNIT::"Purch.-Post") then begin
                        PostingInProgress := false;
                        CurrPage.Update(false);
                        if GetLastErrorText() <> '' then
                            Error(GetLastErrorText());
                        exit;
                    end;

                    POReceivingThresholdMgt.ClearActualReceiptDatesAfterReceive(Rec);
                    // Flag stays set through Close: the page saving the posted record on the way
                    // out must not trip the edit guard.
                    CurrPage.Close();
                end;
            }
        }
        addfirst(Category_Process)
        {
            actionref("TBGC Post To Receive_Promoted"; "TBGC Post To Receive")
            {
            }
            actionref("TBGC Print_Promoted"; "&Print")
            {
            }
        }

        modify(Post_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Preview_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify("Post and &Print_Promoted")
        {
            Visible = not MarketListReceivingMode;
        }
        modify(PostAndNew_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify("Post &Batch_Promoted")
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Release_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Reopen_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify("Create &Whse. Receipt_Promoted")
        {
            Visible = not MarketListReceivingMode;
        }
        modify("Create Inventor&y Put-away/Pick_Promoted")
        {
            Visible = not MarketListReceivingMode;
        }
        modify("Send Intercompany Purchase Order_Promoted")
        {
            Visible = not MarketListReceivingMode;
        }
        modify("Archive Document_Promoted")
        {
            Visible = not MarketListReceivingMode;
        }
        modify(CopyDocument_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(GetRecurringPurchaseLines_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(IncomingDocAttachFile_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(SelectIncomingDoc_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(IncomingDocCard_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(RemoveIncomingDoc_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(CalculateInvoiceDiscount_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(MoveNegativeLines_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Approve_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Reject_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Comment_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Delegate_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Email_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify("&Print_Promoted")
        {
            Visible = not MarketListReceivingMode;
        }
        modify(SendCustom_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(AttachAsPDF_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(SendApprovalRequest_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(CancelApprovalRequest_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Dimensions_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Statistics_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }

        modify("Co&mments_Promoted")
        {
            Visible = not MarketListReceivingMode;
        }
        modify(DocAttach_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Approvals_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Invoices_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Vendor_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Receipts_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(PostedPrepaymentInvoices_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(PostedPrepaymentCrMemos_Promoted)
        {
            Visible = not MarketListReceivingMode;
        }
        modify("O&rder")
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Documents)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Warehouse)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Approval)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Action13)
        {
            Visible = not MarketListReceivingMode;
        }
        modify("F&unctions")
        {
            Visible = not MarketListReceivingMode;
        }
        modify("Request Approval")
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Action17)
        {
            Visible = not MarketListReceivingMode;
        }
        modify("P&osting")
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Print)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Category_Category4)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Category_Category5)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Category_Category7)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Category_Category8)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Category_Category9)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Category_Category10)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Category_Category11)
        {
            Visible = not MarketListReceivingMode;
        }
        modify(Category_Report)
        {
            Visible = not MarketListReceivingMode;
        }
    }

    trigger OnOpenPage()
    begin
        UpdateMarketListReceivingMode();
    end;

    trigger OnAfterGetRecord()
    var
        UserRec: Record User;
    begin
        UpdateMarketListReceivingMode();

        ModifiedByUserName := '';
        if UserRec.Get(Rec.SystemModifiedBy) then
            ModifiedByUserName := UserRec."Full Name";
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if MarketListReceivingMode then
            Error(MarketListHeaderInsertErr);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if MarketListReceivingMode and not PostingInProgress then
            Error(MarketListHeaderEditErr);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if MarketListReceivingMode then
            Error(MarketListHeaderDeleteErr);
    end;

    trigger OnClosePage()
    var
        MarketListReceivingContext: Codeunit "TBGC ML Receiving Context";
    begin
        if MarketListReceivingMode then
            MarketListReceivingContext.ClearPurchaseOrderNo();
    end;

    local procedure UpdateMarketListReceivingMode()
    var
        MarketListReceivingContext: Codeunit "TBGC ML Receiving Context";
    begin
        MarketListReceivingMode := MarketListReceivingContext.IsMarketListReceivingPurchaseOrder(Rec."No.");
        MarketListReadOnlyMode := MarketListReceivingContext.IsMarketListReceivingReadOnly(Rec."No.");
        if MarketListReadOnlyMode then
            CurrPage.Editable(false);
    end;

    var
        MarketListHeaderDeleteErr: Label 'Deleting purchase orders is not allowed when opened from Market List Receiving.';
        MarketListHeaderEditErr: Label 'Purchase order header changes are not allowed when opened from Market List Receiving. You can only update Qty. to Receive on the lines.';
        MarketListHeaderInsertErr: Label 'Creating purchase orders is not allowed when opened from Market List Receiving.';
        ModifiedByUserName: Text;
        MarketListReceivingMode: Boolean;
        MarketListReadOnlyMode: Boolean;
        PostingInProgress: Boolean;
}







