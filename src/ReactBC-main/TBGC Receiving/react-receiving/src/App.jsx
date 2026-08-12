import { useEffect, useRef, useState } from 'react';
import ReceivingShell, { InfoCard, MetricRow, Panel, StatusPill } from './components/ReceivingShell';
import mockOrders from './data/mockOrders';

const RECEIVING_ORDERS_PAGE_SIZE = 15;

function formatDate(value) {
  if (!value) {
    return '-';
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

function formatDateTime(value) {
  if (!value) {
    return '-';
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return date.toLocaleString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

function formatQuantity(value) {
  if (value === null || value === undefined || value === '') {
    return '-';
  }

  const number = Number(value);
  if (Number.isNaN(number)) {
    return value;
  }

  return new Intl.NumberFormat(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(number);
}

function formatText(value) {
  if (value === null || value === undefined || value === '') {
    return '-';
  }

  return value;
}

function getDateOnlyValue(value) {
  if (!value) {
    return '';
  }

  if (typeof value === 'string') {
    const match = value.match(/^(\d{4}-\d{2}-\d{2})/);
    if (match) {
      return match[1];
    }
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return '';
  }

  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function App() {
  const [orders, setOrders] = useState([]);
  const [locationCode, setLocationCode] = useState('');
  const [locationName, setLocationName] = useState('');
  const [locationOptions, setLocationOptions] = useState([]);
  const [selectedLocationFilter, setSelectedLocationFilter] = useState('');
  const [canFilterLocation, setCanFilterLocation] = useState(false);
  const [userId, setUserId] = useState('');
  const [searchText, setSearchText] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [releasedDateFrom, setReleasedDateFrom] = useState('');
  const [releasedDateTo, setReleasedDateTo] = useState('');
  const [orderCounts, setOrderCounts] = useState(null);
  const [isLoadingOrders, setIsLoadingOrders] = useState(false);
  const [hasMoreOrders, setHasMoreOrders] = useState(false);
  const [hasLoadedOrders, setHasLoadedOrders] = useState(false);
  const [viewportWidth, setViewportWidth] = useState(() => window.innerWidth);
  const [viewportHeight, setViewportHeight] = useState(() => window.innerHeight);
  const ordersSkipRef = useRef(0);
  const ordersLoadingRef = useRef(false);
  const ordersHasMoreRef = useRef(false);
  const receivingInitializedRef = useRef(false);
  const filtersRef = useRef({
    locationCode: '',
    searchText: '',
    statusFilter: 'All',
    releasedDateFrom: '',
    releasedDateTo: '',
  });

  useEffect(() => {
    document.title = 'Market List Receiving';

    window.init = (contextJson) => {
      try {
        const context = typeof contextJson === 'string' ? JSON.parse(contextJson) : contextJson;
        setLocationCode(context.locationCode || '');
        setLocationName(context.locationName || '');
        setLocationOptions(Array.isArray(context.locationOptions) ? context.locationOptions : []);
        setSelectedLocationFilter(context.locationCode || '');
        filtersRef.current.locationCode = context.locationCode || '';
        setCanFilterLocation(Boolean(context.canFilterLocation));
        setUserId(context.userId || '');
        receivingInitializedRef.current = true;
      } catch (error) {
        console.error('Failed to parse receiving context:', error);
      }
    };

    window.loadReceivingOrders = (ordersJson) => {
      try {
        const parsedOrders = typeof ordersJson === 'string' ? JSON.parse(ordersJson) : ordersJson;

        if (Array.isArray(parsedOrders)) {
          ordersSkipRef.current = parsedOrders.length;
          ordersHasMoreRef.current = false;
          ordersLoadingRef.current = false;
          setOrders(parsedOrders);
          setHasMoreOrders(false);
          setIsLoadingOrders(false);
          setOrderCounts(null);
          return;
        }

        const nextOrders = Array.isArray(parsedOrders?.orders) ? parsedOrders.orders : [];
        const shouldReset = Boolean(parsedOrders?.reset);

        setOrders((currentOrders) => {
          if (shouldReset) {
            return nextOrders;
          }

          const seenDocumentNos = new Set(currentOrders.map((order) => order.documentNo));
          const appendedOrders = nextOrders.filter((order) => !seenDocumentNos.has(order.documentNo));
          return [...currentOrders, ...appendedOrders];
        });

        ordersSkipRef.current = Number(parsedOrders?.skip || 0) + nextOrders.length;
        ordersHasMoreRef.current = Boolean(parsedOrders?.hasMore);
        ordersLoadingRef.current = false;
        setHasMoreOrders(Boolean(parsedOrders?.hasMore));
        setIsLoadingOrders(false);
        setOrderCounts({
          released: Number(parsedOrders?.releasedOrdersCount || 0),
          lateReleased: Number(parsedOrders?.lateReleasedOrdersCount || 0),
          partial: Number(parsedOrders?.partialOrdersCount || 0),
          fullyReceived: Number(parsedOrders?.fullyReceivedOrdersCount || 0),
        });
      } catch (error) {
        ordersLoadingRef.current = false;
        setIsLoadingOrders(false);
        console.error('Failed to parse receiving orders:', error);
      }
    };

    if (window.Microsoft?.Dynamics?.NAV) {
      try {
        window.Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', []);
      } catch (error) {
        console.warn('ControlAddInReady not available:', error);
      }
    } else {
      setLocationCode('MAIN');
      setLocationName('Main Store');
      setLocationOptions([{ code: 'MAIN', name: 'Main Store', label: 'MAIN - Main Store' }]);
      setSelectedLocationFilter('MAIN');
      filtersRef.current.locationCode = 'MAIN';
      receivingInitializedRef.current = true;
      setCanFilterLocation(false);
      setUserId('LOCAL.TEST');
      setOrders([]);
      ordersSkipRef.current = 0;
      ordersHasMoreRef.current = true;
      setHasMoreOrders(false);
    }

    return () => {
      delete window.init;
      delete window.loadReceivingOrders;
    };
  }, []);

  useEffect(() => {
    const handleResize = () => {
      setViewportWidth(window.innerWidth);
      setViewportHeight(window.innerHeight);
    };

    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
    };
  }, []);

  useEffect(() => {
    if (releasedDateFrom && releasedDateTo && releasedDateTo < releasedDateFrom) {
      setReleasedDateTo('');
    }
  }, [releasedDateFrom, releasedDateTo]);

  useEffect(() => {
    filtersRef.current = {
      locationCode: selectedLocationFilter || locationCode,
      searchText,
      statusFilter,
      releasedDateFrom,
      releasedDateTo,
    };
  }, [selectedLocationFilter, locationCode, searchText, statusFilter, releasedDateFrom, releasedDateTo]);

  const requestReceivingOrdersPage = ({ reset = false, filterOverrides = {} } = {}) => {
    const effectiveFilters = {
      ...filtersRef.current,
      ...filterOverrides,
    };
    const requestedLocationCode = effectiveFilters.locationCode || selectedLocationFilter || locationCode;

    if (ordersLoadingRef.current) {
      return;
    }

    if (!reset && !ordersHasMoreRef.current) {
      return;
    }

    if (reset) {
      ordersSkipRef.current = 0;
      ordersHasMoreRef.current = true;
      setHasMoreOrders(false);
      setOrders([]);
      setOrderCounts(null);
    }

    if (window.Microsoft?.Dynamics?.NAV) {
      try {
        ordersLoadingRef.current = true;
        setIsLoadingOrders(true);
        setHasLoadedOrders(true);
        window.Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('LoadReceivingOrdersPage', [
          requestedLocationCode || '',
          reset ? 0 : ordersSkipRef.current,
          RECEIVING_ORDERS_PAGE_SIZE,
          effectiveFilters.searchText || '',
          effectiveFilters.statusFilter || 'All',
          effectiveFilters.releasedDateFrom || '',
          effectiveFilters.releasedDateTo || '',
        ]);
      } catch (error) {
        ordersLoadingRef.current = false;
        setIsLoadingOrders(false);
        console.error('Failed to load receiving orders page:', error);
      }
      return;
    }

    const allMockOrders = mockOrders.filter((order) => {
      const haystack = [
        order.documentNo,
        order.draftOrderNo,
        order.vendorNo,
        order.vendorName,
        order.locationCode,
      ]
        .join(' ')
        .toLowerCase();
      const matchesSearch = haystack.includes((effectiveFilters.searchText || '').trim().toLowerCase());
      const matchesStatus = effectiveFilters.statusFilter === 'All' || order.status === effectiveFilters.statusFilter;
      const orderDateValue = getDateOnlyValue(order.releasedDate);
      const matchesFrom = !effectiveFilters.releasedDateFrom || orderDateValue >= effectiveFilters.releasedDateFrom;
      const matchesTo = !effectiveFilters.releasedDateTo || orderDateValue <= effectiveFilters.releasedDateTo;
      return matchesSearch && matchesStatus && matchesFrom && matchesTo;
    });
    const start = reset ? 0 : ordersSkipRef.current;
    const nextOrders = allMockOrders.slice(start, start + RECEIVING_ORDERS_PAGE_SIZE);
    ordersSkipRef.current = start + nextOrders.length;
    ordersHasMoreRef.current = ordersSkipRef.current < allMockOrders.length;
    setHasLoadedOrders(true);
    setHasMoreOrders(ordersHasMoreRef.current);
    setOrders((currentOrders) => (reset ? nextOrders : [...currentOrders, ...nextOrders]));
  };

  const handleOrdersScroll = (event) => {
    const { scrollTop, scrollHeight, clientHeight } = event.currentTarget;
    const remainingScroll = scrollHeight - scrollTop - clientHeight;

    if (remainingScroll <= 180) {
      requestReceivingOrdersPage({ reset: false });
    }
  };

  const isCompact = viewportWidth <= 1480;
  const isStacked = viewportWidth <= 1280;
  const isSidebarCompact = viewportWidth <= 1680;
  const isHeaderStacked = viewportWidth <= 1380;
  const isTableCompact = viewportWidth <= 1680;
  const listPanelHeightPx = Math.max(360, Math.min(720, viewportHeight - (isStacked ? 180 : 220)));
  const listPanelHeight = `${listPanelHeightPx}px`;
  const listScrollAreaHeight = `${Math.max(240, listPanelHeightPx - 86)}px`;
  const orderColumns = isTableCompact
    ? 'minmax(140px, 1.05fr) minmax(132px, 0.95fr) minmax(190px, 1.35fr) minmax(112px, 0.9fr) minmax(90px, 0.72fr) minmax(96px, 0.8fr) minmax(118px, 0.9fr) minmax(124px, 0.95fr) minmax(124px, 0.95fr) minmax(132px, 1fr) minmax(170px, 1.2fr) minmax(170px, 1.2fr) 220px'
    : 'minmax(160px, 1.05fr) minmax(148px, 0.95fr) minmax(230px, 1.45fr) minmax(120px, 0.9fr) minmax(96px, 0.72fr) minmax(104px, 0.8fr) minmax(132px, 0.9fr) minmax(132px, 0.95fr) minmax(132px, 0.95fr) minmax(144px, 1fr) minmax(200px, 1.2fr) minmax(190px, 1.15fr) 236px';
  const orderTableMinWidth = isTableCompact ? '1840px' : '2020px';
  const receivableStatuses = ['Released', 'Late Released', 'Partial', 'Fully Received'];

  const baseFilteredOrders = orders.filter((order) => receivableStatuses.includes(order.status));
  const visibleOrders = baseFilteredOrders;

  const openPurchaseOrder = (documentNo, orderLocationCode) => {
    if (!documentNo) {
      return;
    }

    if (window.Microsoft?.Dynamics?.NAV) {
      try {
        window.Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OpenPurchaseOrder', [documentNo, orderLocationCode || selectedLocationFilter || locationCode]);
      } catch (error) {
        console.error('Failed to open purchase order:', error);
      }
    } else {
      console.log(`Open Purchase Order: ${documentNo}`);
    }
  };

  const printPurchaseOrder = (documentNo) => {
    if (!documentNo) {
      return;
    }

    if (window.Microsoft?.Dynamics?.NAV) {
      try {
        window.Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('PrintPurchaseOrder', [documentNo]);
      } catch (error) {
        console.error('Failed to print purchase order:', error);
      }
    } else {
      console.log(`Print Purchase Order: ${documentNo}`);
    }
  };

  const applyReceivingFilters = (filterOverrides = {}) => {
    const nextFilters = {
      ...filtersRef.current,
      locationCode: selectedLocationFilter || locationCode,
      searchText,
      statusFilter,
      releasedDateFrom,
      releasedDateTo,
      ...filterOverrides,
    };

    filtersRef.current = nextFilters;
    requestReceivingOrdersPage({ reset: true, filterOverrides: nextFilters });
  };

  const setStatusQuickFilter = (nextStatus) => {
    setStatusFilter(nextStatus);
    applyReceivingFilters({ statusFilter: nextStatus });
  };

  const changeLocationFilter = (nextLocationCode) => {
    setSelectedLocationFilter(nextLocationCode);
    filtersRef.current.locationCode = nextLocationCode;
  };

  // Helper function to check if order matches date range
  const matchesDateRange = (order) => {
    if (!releasedDateFrom && !releasedDateTo) {
      return true;
    }
    const orderDateValue = getDateOnlyValue(order.releasedDate);
    if (!orderDateValue) {
      return false;
    }

    if (releasedDateFrom) {
      if (orderDateValue < releasedDateFrom) return false;
    }
    if (releasedDateTo) {
      if (orderDateValue > releasedDateTo) return false;
    }
    return true;
  };

  const releasedOrdersCount = orderCounts?.released ?? baseFilteredOrders.filter((order) => order.status === 'Released').length;
  const lateReleasedOrdersCount = orderCounts?.lateReleased ?? baseFilteredOrders.filter((order) => order.status === 'Late Released').length;
  const partialOrdersCount = orderCounts?.partial ?? baseFilteredOrders.filter((order) => order.status === 'Partial').length;
  const fullyReceivedOrdersCount = orderCounts?.fullyReceived ?? baseFilteredOrders.filter((order) => order.status === 'Fully Received').length;
  const activeLocationOption =
    locationOptions.find((option) => option.code === selectedLocationFilter) ||
    locationOptions.find((option) => option.code === locationCode);
  const displayedLocationCode = selectedLocationFilter || locationCode;
  const displayedLocationName = activeLocationOption?.name || locationName;
  const displayedLocationLabel = displayedLocationName
    ? `${displayedLocationCode} - ${displayedLocationName}`
    : (displayedLocationCode || '-');

  return (
    <ReceivingShell
      stacked={isStacked}
      header={
        <section
          style={{
            background: 'linear-gradient(135deg, #0f766e 0%, #155e75 52%, #1d4ed8 100%)',
            color: '#fff',
            borderRadius: '28px',
            padding: isCompact ? '22px' : '28px',
            boxShadow: '0 18px 40px rgba(15, 23, 42, 0.18)',
            position: 'relative',
            overflow: 'hidden',
          }}
        >
          <div
            style={{
              position: 'absolute',
              inset: 0,
              background:
                'radial-gradient(circle at 80% 20%, rgba(255,255,255,0.22), transparent 22%), radial-gradient(circle at 10% 80%, rgba(255,255,255,0.12), transparent 24%)',
              pointerEvents: 'none',
            }}
          />

          <div
            style={{
              position: 'relative',
              display: 'grid',
              gridTemplateColumns: isHeaderStacked ? 'minmax(0, 1fr)' : 'minmax(0, 1.6fr) minmax(320px, 0.9fr)',
              gap: '20px',
              alignItems: 'start',
            }}
          >
            <div style={{ minWidth: 0 }}>
              <div
                style={{
                  display: 'inline-flex',
                  padding: '6px 12px',
                  borderRadius: '999px',
                  background: 'rgba(255,255,255,0.16)',
                  fontSize: '12px',
                  fontWeight: 700,
                  letterSpacing: '0.08em',
                  textTransform: 'uppercase',
                }}
              >
                Receiving Workspace
              </div>

              <h1
                style={{
                  margin: '16px 0 10px',
                  fontSize: isCompact ? '30px' : '40px',
                  lineHeight: 1.02,
                }}
              >
                Market List Receiving
              </h1>

              <p
                style={{
                  margin: 0,
                  maxWidth: isHeaderStacked ? '100%' : '640px',
                  fontSize: '15px',
                  lineHeight: 1.6,
                  color: 'rgba(255,255,255,0.9)',
                }}
              >
                Review purchase orders assigned to your retail location in a focused workspace.
              </p>
            </div>

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
                gap: '12px',
                width: '100%',
                maxWidth: isHeaderStacked ? '100%' : '520px',
                alignSelf: 'start',
              }}
            >
              <InfoCard label="Retail User" value={userId || '-'} />
              <InfoCard label="Location" value={displayedLocationLabel} />
              <InfoCard label="Released Orders" value={String(releasedOrdersCount)} />
              <InfoCard label="Late Released" value={String(lateReleasedOrdersCount)} />
            </div>
          </div>
        </section>
      }
      sidebar={
        <>
          <Panel title="Filter Receiving POs" subtitle="Narrow the list instantly as you work.">
            <div
              style={{
                display: 'grid',
                gap: isCompact ? '10px' : '14px',
                gridTemplateColumns: isSidebarCompact ? 'repeat(2, minmax(0, 1fr))' : 'minmax(0, 1fr)',
                alignItems: 'end',
              }}
            >
              <label style={{ display: 'grid', gap: '8px' }}>
                <span style={labelStyle}>Location</span>
                <select
                  value={selectedLocationFilter}
                  onChange={(event) => changeLocationFilter(event.target.value)}
                  style={{
                    ...inputStyle,
                    background: canFilterLocation ? '#fff' : '#f3f7fb',
                    color: canFilterLocation ? '#132238' : '#6a7b90',
                    cursor: canFilterLocation ? 'pointer' : 'not-allowed',
                  }}
                  disabled={!canFilterLocation}
                >
                  {locationOptions.map((option) => (
                    <option key={option.code} value={option.code}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </label>

              <label style={{ display: 'grid', gap: '8px' }}>
                <span style={labelStyle}>Search</span>
                <input
                  type="text"
                  value={searchText}
                  onChange={(event) => setSearchText(event.target.value)}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter') {
                      applyReceivingFilters();
                    }
                  }}
                  placeholder="PO no., draft no., vendor, location..."
                  style={inputStyle}
                />
              </label>

              <label style={{ display: 'grid', gap: '8px' }}>
                <span style={labelStyle}>Status</span>
                <select
                  value={statusFilter}
                  onChange={(event) => setStatusFilter(event.target.value)}
                  style={inputStyle}
                >
                  <option value="All">All</option>
                  <option value="Released">Released</option>
                  <option value="Late Released">Late Released</option>
                  <option value="Partial">Partial</option>
                  <option value="Fully Received">Fully Received</option>
                </select>
              </label>

              <label style={{ display: 'grid', gap: '8px' }}>
                <span style={labelStyle}>Released Date From</span>
                <input
                  type="date"
                  value={releasedDateFrom}
                  onChange={(event) => setReleasedDateFrom(event.target.value)}
                  style={inputStyle}
                />
              </label>

              <label style={{ display: 'grid', gap: '8px' }}>
                <span style={labelStyle}>Released Date To</span>
                <input
                  type="date"
                  value={releasedDateTo}
                  min={releasedDateFrom || undefined}
                  onChange={(event) => setReleasedDateTo(event.target.value)}
                  style={inputStyle}
                />
              </label>

              <button
                type="button"
                onClick={() => applyReceivingFilters()}
                disabled={isLoadingOrders}
                style={{
                  border: 'none',
                  borderRadius: '14px',
                  padding: '11px 16px',
                  background: isLoadingOrders ? '#90a4b8' : '#132238',
                  color: '#fff',
                  cursor: isLoadingOrders ? 'wait' : 'pointer',
                  fontWeight: 800,
                  minHeight: '42px',
                }}
              >
                Apply Filter
              </button>
            </div>
          </Panel>

          <Panel title="Snapshot" subtitle="Quick view of your assigned workload.">
            <div style={{ display: 'grid', gap: '12px' }}>
              <MetricRow
                label="Released Orders"
                value={String(releasedOrdersCount)}
                tone="#0f766e"
                active={statusFilter === 'Released'}
                onClick={() => setStatusQuickFilter('Released')}
              />
              <MetricRow
                label="Late Released"
                value={String(lateReleasedOrdersCount)}
                tone="#b91c1c"
                active={statusFilter === 'Late Released'}
                onClick={() => setStatusQuickFilter('Late Released')}
              />
              <MetricRow
                label="Partial Orders"
                value={String(partialOrdersCount)}
                tone="#b45309"
                active={statusFilter === 'Partial'}
                onClick={() => setStatusQuickFilter('Partial')}
              />
              <MetricRow
                label="Fully Received"
                value={String(fullyReceivedOrdersCount)}
                tone="#15803d"
                active={statusFilter === 'Fully Received'}
                onClick={() => setStatusQuickFilter('Fully Received')}
              />
            </div>
          </Panel>
        </>
      }
      content={
        <div
          style={{
            height: listPanelHeight,
            minHeight: listPanelHeight,
            maxHeight: listPanelHeight,
            minWidth: 0,
            overflow: 'hidden',
            display: 'flex',
            flexDirection: 'column',
          }}
        >
          <Panel
            title="Receiving Purchase Orders"
            subtitle="Orders assigned to your retail location."
            noPadding
            style={{
              height: listPanelHeight,
              minHeight: listPanelHeight,
              maxHeight: listPanelHeight,
              display: 'flex',
              flexDirection: 'column',
              overflow: 'hidden',
              alignSelf: 'stretch',
              flex: '1 1 auto',
              width: '100%',
            }}
          >
          <div
            style={{
              display: 'flex',
              flex: 1,
              minHeight: 0,
              flexDirection: 'column',
              width: '100%',
              overflow: 'hidden',
            }}
          >
            {visibleOrders.length === 0 ? (
              <div
                style={{
                  padding: '48px 22px',
                  textAlign: 'center',
                  color: '#5a6c81',
                  fontSize: '15px',
                }}
              >
                {isLoadingOrders
                  ? 'Loading receiving purchase orders...'
                  : hasLoadedOrders
                    ? 'No receiving purchase orders found for the current filter.'
                    : 'Apply a filter to load receiving purchase orders.'}
              </div>
            ) : (
              <div
                style={{
                  display: 'flex',
                  flex: 1,
                  flexDirection: 'column',
                  minHeight: 0,
                  width: '100%',
                }}
              >
                <div
                  className="orders-grid-scroll"
                  style={{
                    flex: '0 0 auto',
                    minHeight: listScrollAreaHeight,
                    minWidth: 0,
                    maxWidth: '100%',
                    overflowX: 'auto',
                    overflowY: 'scroll',
                    width: '100%',
                    height: listScrollAreaHeight,
                    maxHeight: listScrollAreaHeight,
                    scrollbarGutter: 'stable both-edges',
                    overscrollBehavior: 'contain',
                    WebkitOverflowScrolling: 'touch',
                  }}
                >
                  <div
                    style={{
                      minWidth: orderTableMinWidth,
                      display: 'flex',
                      flexDirection: 'column',
                    }}
                  >
                    <div
                      style={{
                        position: 'sticky',
                        top: 0,
                        zIndex: 2,
                        display: 'grid',
                        gridTemplateColumns: orderColumns,
                        gap: '12px',
                        padding: '12px 16px 10px',
                        fontSize: '12px',
                        fontWeight: 700,
                        textTransform: 'uppercase',
                        letterSpacing: '0.06em',
                        color: '#6a7b90',
                        background: 'rgba(255,255,255,0.96)',
                        borderBottom: '1px solid rgba(19, 34, 56, 0.08)',
                      }}
                    >
                      <span>PO No.</span>
                      <span>Draft Order No.</span>
                      <span>Vendor</span>
                      <span style={{ textAlign: 'center' }}>Status</span>
                      <span style={{ textAlign: 'center' }}>Received</span>
                      <span style={{ textAlign: 'center' }}>Remaining</span>
                      <span style={{ textAlign: 'center' }}>Order Date</span>
                      <span style={{ textAlign: 'center' }}>Released Date</span>
                      <span style={{ textAlign: 'center' }}>Last Receipt</span>
                      <span style={{ textAlign: 'center' }}>Expected Receipt</span>
                      <span style={{ textAlign: 'center' }}>System Modified By</span>
                      <span style={{ textAlign: 'center' }}>System Modified At</span>
                      <span style={stickyActionHeaderStyle}>Action</span>
                    </div>

                    {visibleOrders.map((order) => (
                      <div
                        key={order.documentNo}
                        style={{
                          display: 'grid',
                          gridTemplateColumns: orderColumns,
                          gap: '12px',
                          alignItems: 'center',
                          padding: '16px',
                          borderTop: '1px solid rgba(19, 34, 56, 0.07)',
                          background: 'rgba(255,255,255,0.88)',
                        }}
                      >
                        <div>
                          <div style={{ fontWeight: 800, color: '#132238', fontSize: '16px' }}>
                            {order.documentNo}
                          </div>
                          <div style={{ fontSize: '12px', color: '#6a7b90', marginTop: '4px' }}>
                            {order.locationCode || '-'}
                          </div>
                        </div>

                        <div style={{ fontSize: '16px', fontWeight: 700, color: '#132238' }}>
                          {formatText(order.draftOrderNo)}
                        </div>

                        <div>
                          <div style={{ fontSize: '16px', fontWeight: 700, color: '#132238' }}>
                            {order.vendorName || '-'}
                          </div>
                          <div style={{ fontSize: '12px', color: '#6a7b90', marginTop: '4px' }}>
                            {order.vendorNo || '-'}
                          </div>
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'center' }}>
                          <StatusPill status={order.status} />
                        </div>

                        <div style={{ fontSize: '16px', fontWeight: 700, color: '#132238', textAlign: 'center' }}>
                          {formatQuantity(order.receivedQty)}
                        </div>

                        <div style={{ fontSize: '16px', fontWeight: 700, color: '#132238', textAlign: 'center' }}>
                          {formatQuantity(order.remainingQty)}
                        </div>

                        <div style={{ fontSize: '16px', fontWeight: 700, color: '#132238', textAlign: 'center' }}>
                          {formatDate(order.orderDate)}
                        </div>

                        <div style={{ fontSize: '16px', fontWeight: 700, color: '#132238', textAlign: 'center' }}>
                          {formatDateTime(order.releasedDate)}
                        </div>

                        <div style={{ fontSize: '16px', fontWeight: 700, color: '#132238', textAlign: 'center' }}>
                          {formatDate(order.lastReceiptDate)}
                        </div>

                        <div style={{ fontSize: '16px', fontWeight: 700, color: '#132238', textAlign: 'center' }}>
                          {formatDate(order.expectedReceiptDate)}
                        </div>

                        <div style={{ fontSize: '16px', fontWeight: 700, color: '#132238', textAlign: 'center', wordBreak: 'break-word' }}>
                          {formatText(order.systemModifiedBy)}
                        </div>

                        <div style={{ fontSize: '16px', fontWeight: 700, color: '#132238', textAlign: 'center' }}>
                          {formatDateTime(order.systemModifiedAt)}
                        </div>

                        <div style={stickyActionCellStyle}>
                          <button
                            onClick={() => openPurchaseOrder(order.documentNo, order.locationCode)}
                            style={{
                              border: 'none',
                              borderRadius: '999px',
                              padding: '10px 16px',
                              background: '#132238',
                              color: '#fff',
                              cursor: 'pointer',
                              fontWeight: 700,
                              minWidth: '104px',
                            }}
                          >
                            {order.status === 'Fully Received' || order.status === 'Open' ? 'Open PO' : 'Receive PO'}
                          </button>
                          <button
                            onClick={() => printPurchaseOrder(order.documentNo)}
                            style={{
                              border: '1px solid rgba(19, 34, 56, 0.16)',
                              borderRadius: '999px',
                              padding: '10px 16px',
                              background: '#fff',
                              color: '#132238',
                              cursor: 'pointer',
                              fontWeight: 700,
                              minWidth: '92px',
                            }}
                          >
                            Print PO
                          </button>
                        </div>
                      </div>
                    ))}

                    {(isLoadingOrders || hasMoreOrders) && (
                      <button
                        type="button"
                        onClick={() => requestReceivingOrdersPage({ reset: false })}
                        disabled={isLoadingOrders}
                        style={{
                          width: '100%',
                          border: 'none',
                          borderTop: '1px solid rgba(19, 34, 56, 0.07)',
                          padding: '14px 18px',
                          color: '#5a6c81',
                          fontSize: '13px',
                          fontWeight: 800,
                          textAlign: 'center',
                          background: '#fff',
                          cursor: isLoadingOrders ? 'wait' : 'pointer',
                        }}
                      >
                        {isLoadingOrders ? 'Loading more purchase orders...' : 'Load more purchase orders'}
                      </button>
                    )}
                  </div>
                </div>
              </div>
            )}
          </div>
          </Panel>
        </div>
      }
    />
  );
}

const labelStyle = {
  fontSize: '12px',
  fontWeight: 700,
  letterSpacing: '0.04em',
  textTransform: 'uppercase',
  color: '#5a6c81',
};

const inputStyle = {
  width: '100%',
  border: '1px solid rgba(19, 34, 56, 0.12)',
  borderRadius: '14px',
  padding: '10px 14px',
  color: '#132238',
  background: '#fff',
  outline: 'none',
};

const stickyActionHeaderStyle = {
  position: 'sticky',
  right: 0,
  zIndex: 3,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  minWidth: '220px',
  padding: '0 18px',
  boxSizing: 'border-box',
  textAlign: 'center',
  whiteSpace: 'nowrap',
  background: '#ffffff',
  borderLeft: '1px solid rgba(19, 34, 56, 0.08)',
};

const stickyActionCellStyle = {
  position: 'sticky',
  right: 0,
  zIndex: 1,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  minWidth: '220px',
  gap: '8px',
  flexWrap: 'wrap',
  background: '#ffffff',
  borderLeft: '1px solid rgba(19, 34, 56, 0.08)',
  padding: '4px 18px 4px 12px',
  boxSizing: 'border-box',
};

export default App;










