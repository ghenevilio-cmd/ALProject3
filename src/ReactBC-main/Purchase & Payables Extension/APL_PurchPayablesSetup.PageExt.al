pageextension 80297 "APL Purch Payables Setup Ext" extends "Purchases & Payables Setup"
{
    layout
    {
        addlast(General)
        {
            field("APL Order History Ret. Days"; Rec."APL Order History Ret. Days")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies how many days APL order history is kept. Use 0 to keep the history indefinitely.';
            }
            field("APL Draft Rel. Date Max Days"; Rec."APL Draft Rel. Date Max Days")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies how many days from today a released date can be assigned for draft orders. Use 0 to allow any future date.';
            }
            field("APL PO Releasing Cut Off Time"; Rec."APL PO Releasing Cut Off Time")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the cutoff time for purchase order releasing. Orders released after this time are marked as Late Released.';
            }
            field("APL Partial Rcvg View Days"; Rec."APL Partial Rcvg View Days")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies how many days a partially received purchase order remains visible in Market List Receiving, starting from its first posted receipt date. Use 0 to keep partial orders visible indefinitely.';
            }
            field("APL Require End Date Price Chg"; Rec."APL Require End Date Price Chg")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether an Ending Date is required before changing Direct Unit Cost on an existing Approved Product List line.';
            }
        }
    }
}
