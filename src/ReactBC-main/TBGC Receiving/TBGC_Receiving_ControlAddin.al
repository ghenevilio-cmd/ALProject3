controladdin "TBGC Receiving Control Addin"
{
    Scripts = 'react-receiving/dist/assets/index-CZgWARzN.js';
    StyleSheets = 'react-receiving/dist/assets/index-CUjR20cn.css';
    StartupScript = 'react-receiving/startup.js';

    HorizontalStretch = true;
    VerticalStretch = true;
    RequestedHeight = 900;
    MinimumHeight = 700;
    RequestedWidth = 1600;
    MinimumWidth = 1100;

    procedure init(ContextJson: Text);
    procedure loadReceivingOrders(OrdersJson: Text);
    event ControlAddInReady();
    event OpenPurchaseOrder(DocumentNo: Text; LocationCode: Text);
    event PrintPurchaseOrder(DocumentNo: Text);
    event LocationFilterChanged(LocationCode: Text);
    event LoadReceivingOrdersPage(LocationCode: Text; Skip: Integer; Take: Integer; SearchText: Text; StatusFilter: Text; ReleasedDateFrom: Text; ReleasedDateTo: Text);
}



