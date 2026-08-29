controladdin "POS Control Addin"
{
    Scripts = 'react-pos/dist/assets/index-B4k0RS3I.js';
    StyleSheets = 'react-pos/dist/assets/index-BrhGaniE.css';
    StartupScript = 'react-pos/startup.js';

    HorizontalStretch = true;
    VerticalStretch = true;
    RequestedHeight = 600;
    procedure loadItems(ItemsJson: Text);
    procedure loadLastOrder(LastOrderJson: Text);
    procedure loadOrderHistory(OrderHistoryJson: Text);
    procedure loadDraftSummary(DraftSummaryJson: Text);
    procedure init(SettingsJson: Text);
    procedure OnCheckoutSuccess(ResultJson: Text);
    procedure OnCheckoutError(ErrorMessage: Text);
    event OnLocationChanged(LocationCode: Text);
    event OnLoadItemsPage(LocationCode: Text; Skip: Integer; Take: Integer; SearchText: Text);
    event OnCreatePurchaseOrder(CartJson: Text);
    event OnCreateDraftPurchaseOrder(CartJson: Text);
    event OnOpenDraftOrders(LocationCode: Text);
    event OnLoadLatestOrderHistory(LocationCode: Text);
    event ControlAddInReady();
}



