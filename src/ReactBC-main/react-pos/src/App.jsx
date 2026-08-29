import { useState, useEffect, useRef } from 'react';
import LayoutSplitter from './components/LayoutSplitter';
import ItemGrid from './components/ItemGrid';
import CartSidebar from './components/CartSidebar';
import { getOrderingDayDisabledState } from './orderingDay';

const QUANTITY_DECIMALS = 5;
const ITEM_PAGE_SIZE = 15;

const truncateDecimals = (value, decimals = QUANTITY_DECIMALS) => {
  const numericValue = Number(value);

  if (Number.isNaN(numericValue)) {
    return 0;
  }

  const factor = 10 ** decimals;
  return Math.trunc(numericValue * factor) / factor;
};

const normalizeMinimumQuantity = (value) => {
  const parsedValue = Number(value);

  if (Number.isNaN(parsedValue) || parsedValue <= 0) {
    return 0;
  }

  return truncateDecimals(parsedValue);
};

const normalizeCartLine = (line, sourceItem = null) => {
  const minimumQuantity = normalizeMinimumQuantity(line.minimumQuantity);
  const parsedQuantity = Number(line.quantity);
  const quantity = Number.isNaN(parsedQuantity) ? 0 : parsedQuantity;
  const normalizedQuantity = quantity > 0 ? quantity : (minimumQuantity || 1);

  return {
    cartLineId: createCartLineId(line),
    id: line.itemId || line.id,
    name: line.name,
    vendorNo: line.vendorNo,
    vendorName: line.vendorName || sourceItem?.vendorName || '',
    vendorMinimumOrderAmount: Number(line.vendorMinimumOrderAmount ?? sourceItem?.vendorMinimumOrderAmount ?? 0) || 0,
    brandCode: line.brandCode,
    brandDescription: line.brandDescription,
    uom: line.uom,
    price: line.price,
    category: line.category || sourceItem?.category || '',
    familyCode: line.familyCode || sourceItem?.familyCode || '',
    minimumQuantity,
    quantity: truncateDecimals(normalizedQuantity),
  };
};

const createCartLineId = (item) =>
  `${item.itemId || item.id}-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;

const formatDateInputValue = (date) => {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');

  return `${year}-${month}-${day}`;
};

const parseTimeStringToMinutes = (timeValue) => {
  if (!timeValue) {
    return null;
  }

  const parts = String(timeValue).split(':');
  if (parts.length < 2) {
    return null;
  }

  const hours = Number(parts[0]);
  const minutes = Number(parts[1]);
  const seconds = Number(parts[2] || 0);

  if ([hours, minutes, seconds].some((part) => Number.isNaN(part))) {
    return null;
  }

  return (hours * 60) + minutes + (seconds / 60);
};

const isAllowedReleasedWeekday = (dateValue) => {
  if (!dateValue) {
    return false;
  }

  const date = new Date(`${dateValue}T00:00:00`);
  if (Number.isNaN(date.getTime())) {
    return false;
  }

  const day = date.getDay();
  return day === 1 || day === 3 || day === 5;
};

const getItemFamilyCode = (item) => (item?.familyCode || '').trim();
const getVendorCode = (item) => (item?.vendorNo || '').trim();
const getVendorMinimumOrderAmount = (item) => Number(item?.vendorMinimumOrderAmount) || 0;
const restrictedFamilyCodes = ['OSI', 'SW', 'UF'];

const getNormalizedOrderHistoryLines = (lines, availableItems) =>
  (lines || []).map((line) => {
    const matchedItem = (availableItems || []).find(
      (item) =>
        (item.id === (line.itemId || line.id)) &&
        ((item.brandCode || '') === (line.brandCode || '')) &&
        ((item.uom || '') === (line.uom || ''))
    ) || (availableItems || []).find((item) => item.id === (line.itemId || line.id));

    return normalizeCartLine(line, matchedItem);
  });

const getDistinctFamilyCodes = (lines) => [...new Set((lines || []).map((line) => getItemFamilyCode(line)).filter(Boolean))];
const getDistinctVendorCodes = (lines) => [...new Set((lines || []).map((line) => getVendorCode(line)).filter(Boolean))];
const hasRestrictedFamilyMix = (lines) => {
  const familyCodes = getDistinctFamilyCodes(lines).map((familyCode) => familyCode.toUpperCase());

  return familyCodes.length > 1 && familyCodes.some((familyCode) => restrictedFamilyCodes.includes(familyCode));
};

function App() {
  const availableItemsRef = useRef([]);
  const itemSkipRef = useRef(0);
  const itemLoadingRef = useRef(false);
  const itemHasMoreRef = useRef(true);
  const itemSearchQueryRef = useRef('');
  const itemSearchDebounceRef = useRef(null);
  const locationCodeRef = useRef('');
  const isTemplateMasterRef = useRef(false);
  const [locationOptions, setLocationOptions] = useState([]);
  const [checkoutMode, setCheckoutMode] = useState('release');
  const [availableItems, setAvailableItems] = useState([]);
  const [itemSearchQuery, setItemSearchQuery] = useState('');
  const [isItemsLoading, setIsItemsLoading] = useState(false);
  const [hasMoreItems, setHasMoreItems] = useState(true);
  const [cartItems, setCartItems] = useState([]);
  const [vendorNo, setVendorNo] = useState('');
  const [isTemplateMaster, setIsTemplateMaster] = useState(false);
  const [locationCode, setLocationCode] = useState('');
  const [locationName, setLocationName] = useState('');
  const [draftOrderCount, setDraftOrderCount] = useState(0);
  const [expectedDeliveryDate, setExpectedDeliveryDate] = useState('');
  const [releasedDate, setReleasedDate] = useState('');
  const [draftReleasedDateMaxDays, setDraftReleasedDateMaxDays] = useState(0);
  const [poReleasingCutOffTime, setPOReleasingCutOffTime] = useState('');
  const [isOrderingDayAllowed, setIsOrderingDayAllowed] = useState(true);
  const [isDraftOrderingDayAllowed, setIsDraftOrderingDayAllowed] = useState(true);
  const [allowFromTime, setAllowFromTime] = useState('');
  const [allowToTime, setAllowToTime] = useState('');
  const [draftAllowFromTime, setDraftAllowFromTime] = useState('');
  const [draftAllowToTime, setDraftAllowToTime] = useState('');
  const [nowTick, setNowTick] = useState(() => new Date());
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [processingAction, setProcessingAction] = useState(null);
  const [showReleasedDateDialog, setShowReleasedDateDialog] = useState(false);
  const [showCheckoutConfirm, setShowCheckoutConfirm] = useState(false);
  const [checkoutCountdown, setCheckoutCountdown] = useState(0);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [createdPONumbers, setCreatedPONumbers] = useState([]);
  const [createdPOStatus, setCreatedPOStatus] = useState('released');
  const [showInfoModal, setShowInfoModal] = useState(false);
  const [infoModalMessage, setInfoModalMessage] = useState('');
  const [lastOrderHistory, setLastOrderHistory] = useState(null);

  const todayString = formatDateInputValue(new Date());
  const releasedDateMaxString =
    draftReleasedDateMaxDays > 0
      ? formatDateInputValue(new Date(Date.now() + draftReleasedDateMaxDays * 24 * 60 * 60 * 1000))
      : '';
  const now = nowTick;
  const currentTimeInMinutes = (now.getHours() * 60) + now.getMinutes() + (now.getSeconds() / 60);
  const releasingCutOffInMinutes = parseTimeStringToMinutes(poReleasingCutOffTime);
  const isLateCheckoutCutoffReached =
    releasingCutOffInMinutes !== null && currentTimeInMinutes > releasingCutOffInMinutes;
  const isOutsideTimeWindow = (fromTime, toTime) => {
    const fromMinutes = parseTimeStringToMinutes(fromTime);
    const toMinutes = parseTimeStringToMinutes(toTime);

    // Blank From or To means no time restriction for that button.
    if (fromMinutes === null || toMinutes === null) {
      return false;
    }

    return currentTimeInMinutes < fromMinutes || currentTimeInMinutes > toMinutes;
  };
  const isOrderingDayDisabled =
    getOrderingDayDisabledState({ isOrderingDayAllowed }) || isOutsideTimeWindow(allowFromTime, allowToTime);
  const isDraftOrderingDayDisabled =
    getOrderingDayDisabledState({ isOrderingDayAllowed: isDraftOrderingDayAllowed })
    || isOutsideTimeWindow(draftAllowFromTime, draftAllowToTime);
  useEffect(() => {
    const intervalId = setInterval(() => setNowTick(new Date()), 30000);
    return () => clearInterval(intervalId);
  }, []);

  useEffect(() => {
    availableItemsRef.current = availableItems;
  }, [availableItems]);

  useEffect(() => {
    locationCodeRef.current = locationCode;
  }, [locationCode]);

  useEffect(() => {
    isTemplateMasterRef.current = isTemplateMaster;
  }, [isTemplateMaster]);

  useEffect(() => {
    itemSearchQueryRef.current = itemSearchQuery;
  }, [itemSearchQuery]);

  useEffect(() => {
    document.title = 'Market List';

    console.log('React POS loading... Setting up BC Bridge.');

    window.loadItems = (jsonData) => {
      try {
        const payload = typeof jsonData === 'string' ? JSON.parse(jsonData) : jsonData;

        if (payload && !Array.isArray(payload) && Array.isArray(payload.items)) {
          if ((payload.searchText || '') !== itemSearchQueryRef.current) {
            return;
          }

          const pageItems = payload.items;
          const shouldReset = payload.reset !== false;
          const returnedCount = Number(payload.returnedCount ?? pageItems.length) || 0;
          const nextHasMore = payload.hasMore !== false && returnedCount >= ITEM_PAGE_SIZE;

          setAvailableItems((currentItems) => {
            const baseItems = shouldReset ? [] : currentItems;
            const seenKeys = new Set(baseItems.map((item) => item.lineId || `${item.id}|${item.vendorNo}|${item.brandCode}|${item.uom}`));
            const mergedItems = [...baseItems];

            pageItems.forEach((item) => {
              const key = item.lineId || `${item.id}|${item.vendorNo}|${item.brandCode}|${item.uom}`;
              if (seenKeys.has(key)) {
                return;
              }

              seenKeys.add(key);
              mergedItems.push(item);
            });

            availableItemsRef.current = mergedItems;
            return mergedItems;
          });

          itemSkipRef.current = (Number(payload.skip) || 0) + returnedCount;
          itemHasMoreRef.current = nextHasMore;
          itemLoadingRef.current = false;
          setHasMoreItems(nextHasMore);
          setIsItemsLoading(false);
          return;
        }

        const items = Array.isArray(payload) ? payload : [];
        availableItemsRef.current = items;
        itemSkipRef.current = items.length;
        itemHasMoreRef.current = false;
        itemLoadingRef.current = false;
        setAvailableItems(items);
        setHasMoreItems(false);
        setIsItemsLoading(false);
      } catch (error) {
        itemLoadingRef.current = false;
        setIsItemsLoading(false);
        console.error('Failed to parse items from BC:', error);
      }
    };

    window.init = (settingsData) => {
      try {
        const settings = typeof settingsData === 'string' ? JSON.parse(settingsData) : settingsData;
        const nextLocationOptions = Array.isArray(settings.locationOptions) ? settings.locationOptions : [];
        const currentLocationCode = locationCodeRef.current;
        const currentLocationOption = nextLocationOptions.find((location) => location.code === currentLocationCode);
        console.log('React POS initialized:', settings);

        setVendorNo(settings.vendorNo || '');
        setIsTemplateMaster(Boolean(settings.isTemplateMaster));
        setDraftReleasedDateMaxDays(Number(settings.draftReleasedDateMaxDays) || 0);
        setPOReleasingCutOffTime(settings.poReleasingCutOffTime || '');
        setIsOrderingDayAllowed(settings.isOrderingDayAllowed !== false);
        setIsDraftOrderingDayAllowed(settings.isDraftOrderingDayAllowed !== false);
        setAllowFromTime(settings.allowFromTime || '');
        setAllowToTime(settings.allowToTime || '');
        setDraftAllowFromTime(settings.draftAllowFromTime || '');
        setDraftAllowToTime(settings.draftAllowToTime || '');
        setLocationOptions(nextLocationOptions);

        if (currentLocationOption) {
          setLocationCode(currentLocationCode);
          setLocationName(currentLocationOption.name || '');
        } else {
          setLocationCode(settings.locationCode || '');
          setLocationName(settings.locationName || '');
        }
      } catch (error) {
        console.error('Failed to parse init settings from BC:', error);
      }
    };

    window.loadDraftSummary = (draftSummaryJson) => {
      try {
        const draftSummary = typeof draftSummaryJson === 'string' ? JSON.parse(draftSummaryJson) : draftSummaryJson;
        setDraftOrderCount(Number(draftSummary?.draftOrderCount) || 0);
      } catch (error) {
        console.error('Failed to parse draft summary from BC:', error);
        setDraftOrderCount(0);
      }
    };

    window.loadLastOrder = (lastOrderJson) => {
      try {
        const lastOrder = typeof lastOrderJson === 'string' ? JSON.parse(lastOrderJson) : lastOrderJson;
        setLastOrderHistory(lastOrder?.hasOrderHistory ? lastOrder : null);
      } catch (error) {
        console.error('Failed to parse last order history from BC:', error);
        setLastOrderHistory(null);
      }
    };

    window.loadOrderHistory = (orderHistoryJson) => {
      try {
        if (isTemplateMasterRef.current) {
          setInfoModalMessage('You are not allowed to order.');
          setShowInfoModal(true);
          return;
        }

        const orderHistory = typeof orderHistoryJson === 'string' ? JSON.parse(orderHistoryJson) : orderHistoryJson;

        if (!orderHistory?.hasOrderHistory || !Array.isArray(orderHistory.lines) || orderHistory.lines.length === 0) {
          setInfoModalMessage('No saved order history was found.');
          setShowInfoModal(true);
          return;
        }

        const normalizedLines = getNormalizedOrderHistoryLines(orderHistory.lines, availableItemsRef.current);
        if (hasRestrictedFamilyMix(normalizedLines)) {
          setInfoModalMessage('Items under OSI, SW, or UF cannot be ordered together with other item families.');
          setShowInfoModal(true);
          return;
        }

        setLastOrderHistory(orderHistory);
        setCartItems(normalizedLines);
        setInfoModalMessage('The selected order history has been loaded into the cart.');
        setShowInfoModal(true);
      } catch (error) {
        console.error('Failed to parse selected order history from BC:', error);
      }
    };

    if (window.Microsoft && window.Microsoft.Dynamics && window.Microsoft.Dynamics.NAV) {
      try {
        window.Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', []);
      } catch (e) {
        console.warn('ControlAddInReady not defined in BC or testing locally.');
      }
    }

    window.OnCheckoutSuccess = (resultJson) => {
      setIsSubmitting(false);
      setProcessingAction(null);

      try {
        const result = typeof resultJson === 'string' ? JSON.parse(resultJson) : resultJson;
        const documentNumbers = result.documentNumbers || result.poNumbers || [];
        const status = result.status || 'draft';
        const warningMessage = result.warningMessage || '';

        console.log('Checkout success from BC', result);

        setCartItems([]);
        setVendorNo('');
        setExpectedDeliveryDate('');
        setReleasedDate('');
        setCreatedPONumbers(documentNumbers);
        setCreatedPOStatus(status);
        setShowSuccessModal(true);

        if (warningMessage) {
          setInfoModalMessage(warningMessage);
          setShowInfoModal(true);
        }
      } catch (error) {
        console.error('Failed to parse checkout result:', error);
        setCartItems([]);
        setVendorNo('');
        setExpectedDeliveryDate('');
        setReleasedDate('');
        setCreatedPONumbers([]);
        setCreatedPOStatus(checkoutMode === 'draft' ? 'draft' : 'checkout');
        setShowSuccessModal(true);
      }
    };

    window.OnCheckoutError = (errorMessage) => {
      setIsSubmitting(false);
      setProcessingAction(null);
      setShowCheckoutConfirm(false);
      setInfoModalMessage(errorMessage || 'Checkout failed.');
      setShowInfoModal(true);
    };

    return () => {
      delete window.loadItems;
      delete window.loadLastOrder;
      delete window.loadOrderHistory;
      delete window.loadDraftSummary;
      delete window.init;
      delete window.OnCheckoutSuccess;
      if (itemSearchDebounceRef.current) {
        window.clearTimeout(itemSearchDebounceRef.current);
      }
      delete window.OnCheckoutError;
    };
  }, []);

  useEffect(() => {
    if (cartItems.length === 0) {
      setExpectedDeliveryDate('');
      return;
    }
  }, [cartItems]);

  useEffect(() => {
    if (!showCheckoutConfirm) {
      setCheckoutCountdown(0);
      return undefined;
    }

    setCheckoutCountdown(3);

    const intervalId = window.setInterval(() => {
      setCheckoutCountdown((currentValue) => {
        if (currentValue <= 1) {
          window.clearInterval(intervalId);
          return 0;
        }

        return currentValue - 1;
      });
    }, 1000);

    return () => {
      window.clearInterval(intervalId);
    };
  }, [showCheckoutConfirm]);

  const handleAddToCart = (item) => {
    if (isTemplateMaster) {
      setInfoModalMessage('You are not allowed to order.');
      setShowInfoModal(true);
      return;
    }

    if (hasRestrictedFamilyMix([...cartItems, item])) {
      setInfoModalMessage('Items under OSI, SW, or UF cannot be ordered together with other item families.');
      setShowInfoModal(true);
      return;
    }

    const minimumQuantity = normalizeMinimumQuantity(item.minimumQuantity);

    setCartItems((prev) => [
      ...prev,
      {
        ...normalizeCartLine({
          ...item,
          quantity: minimumQuantity || 1,
        }),
      },
    ]);
  };

  const handleUpdateQuantity = (cartLineId, newQuantity) => {
    setCartItems((prev) =>
      prev.map((item) =>
        item.cartLineId === cartLineId
          ? {
              ...item,
              quantity:
                newQuantity === ''
                  ? ''
                  : truncateDecimals(Math.max(Number(newQuantity) || 0, 0)),
            }
          : item
      )
    );
  };

  const handleRemove = (cartLineId) => {
    setCartItems((prev) =>
      prev.filter((item) => item.cartLineId !== cartLineId)
    );
  };

  const getCartTotalAmount = () =>
    truncateDecimals(
      cartItems.reduce(
        (total, item) => total + ((Number(item.price) || 0) * (Number(item.quantity) || 0)),
        0
      ),
      2
    );

  const validateVendorMinimumOrderAmount = () => {
    if (cartItems.length === 0) {
      return true;
    }

    const vendorTotals = new Map();

    cartItems.forEach((item) => {
      const key = item.vendorNo || '';
      const current = vendorTotals.get(key) || {
        totalAmount: 0,
        minimumOrderAmount: Number(item.vendorMinimumOrderAmount) || 0,
        vendorLabel: item.vendorName || item.vendorNo || 'this vendor',
      };

      current.totalAmount += (Number(item.price) || 0) * (Number(item.quantity) || 0);
      current.minimumOrderAmount = Math.max(current.minimumOrderAmount, Number(item.vendorMinimumOrderAmount) || 0);
      vendorTotals.set(key, current);
    });

    for (const [, vendorSummary] of vendorTotals) {
      if (vendorSummary.minimumOrderAmount > 0 && vendorSummary.totalAmount < vendorSummary.minimumOrderAmount) {
        setInfoModalMessage(
          `Minimum order not reached for ${vendorSummary.vendorLabel}. Required minimum amount is ${vendorSummary.minimumOrderAmount.toFixed(2)}, but current order total is ${vendorSummary.totalAmount.toFixed(2)}.`
        );
        setShowInfoModal(true);
        return false;
      }
    }

    return true;
  };

  const openCheckoutConfirm = (mode) => {
    if (isSubmitting) return;

    if (isTemplateMaster) {
      setInfoModalMessage('You are not allowed to order.');
      setShowInfoModal(true);
      return;
    }

    if (hasRestrictedFamilyMix(cartItems)) {
      setInfoModalMessage('Items under OSI, SW, or UF cannot be ordered together with other item families.');
      setShowInfoModal(true);
      return;
    }

    if (!validateVendorMinimumOrderAmount()) {
      return;
    }

    if (!expectedDeliveryDate) {
      setInfoModalMessage('Please select a Need by Date.');
      setShowInfoModal(true);
      return;
    }

    if (expectedDeliveryDate < todayString) {
      setInfoModalMessage('Need by Date cannot be earlier than today.');
      setShowInfoModal(true);
      return;
    }

    setCheckoutMode(mode);
    setShowCheckoutConfirm(true);
  };

  const handleCheckoutClick = () => {
    openCheckoutConfirm('checkout');
  };

  const handleAddToDraftClick = () => {
    if (isSubmitting) return;

    if (isTemplateMaster) {
      setInfoModalMessage('You are not allowed to order.');
      setShowInfoModal(true);
      return;
    }

    if (!validateVendorMinimumOrderAmount()) {
      return;
    }

    // Validate Need by Date FIRST before showing Released Date dialog
    if (!expectedDeliveryDate) {
      setInfoModalMessage('Please select a Need by Date.');
      setShowInfoModal(true);
      return;
    }

    if (expectedDeliveryDate < todayString) {
      setInfoModalMessage('Need by Date cannot be earlier than today.');
      setShowInfoModal(true);
      return;
    }

    // If Need by Date is valid, then show Released Date dialog
    setCheckoutMode('draft');
    setShowReleasedDateDialog(true);
  };

  const handleReleasedDateConfirm = () => {
    if (!releasedDate) {
      setInfoModalMessage('Please select a Released Date.');
      setShowInfoModal(true);
      return;
    }

    if (releasedDate < formatDateInputValue(new Date())) {
      setInfoModalMessage('Released Date cannot be earlier than today.');
      setShowInfoModal(true);
      return;
    }

    if (expectedDeliveryDate < releasedDate) {
      setInfoModalMessage('Need by Date cannot be earlier than Released Date.');
      setShowInfoModal(true);
      return;
    }

    if (draftReleasedDateMaxDays > 0 && releasedDate > releasedDateMaxString) {
      setInfoModalMessage(`Released Date cannot be later than ${releasedDateMaxString}.`);
      setShowInfoModal(true);
      return;
    }

    if (!isAllowedReleasedWeekday(releasedDate)) {
      setInfoModalMessage('Released Date can only be Monday, Wednesday, or Friday.');
      setShowInfoModal(true);
      return;
    }

    // All validations passed, show checkout confirmation
    setShowReleasedDateDialog(false);
    setCheckoutMode('draft');
    setShowCheckoutConfirm(true);
  };

  const handleLoadLastOrder = () => {
    if (isTemplateMaster) {
      setInfoModalMessage('You are not allowed to order.');
      setShowInfoModal(true);
      return;
    }

    if (!lastOrderHistory || !Array.isArray(lastOrderHistory.lines) || lastOrderHistory.lines.length === 0) {
      setInfoModalMessage('No saved order history was found for this location.');
      setShowInfoModal(true);
      return;
    }

    if (window.Microsoft && window.Microsoft.Dynamics && window.Microsoft.Dynamics.NAV) {
      try {
        window.Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnLoadLatestOrderHistory', [locationCode]);
      } catch (error) {
        console.error('Error invoking OnLoadLatestOrderHistory:', error);
      }
      return;
    }

    const normalizedLines = getNormalizedOrderHistoryLines(lastOrderHistory.lines, availableItems);
    if (hasRestrictedFamilyMix(normalizedLines)) {
      setInfoModalMessage('Items under OSI, SW, or UF cannot be ordered together with other item families.');
      setShowInfoModal(true);
      return;
    }

    setCartItems(normalizedLines);
    setInfoModalMessage('The latest saved order for this location has been loaded into the cart.');
    setShowInfoModal(true);
  };

  const requestItemsPage = ({ reset = false, searchQuery = itemSearchQueryRef.current } = {}) => {
    if (!window.Microsoft || !window.Microsoft.Dynamics || !window.Microsoft.Dynamics.NAV) {
      return;
    }

    if (!locationCodeRef.current) {
      return;
    }

    if (!reset && (itemLoadingRef.current || !itemHasMoreRef.current)) {
      return;
    }

    if (reset) {
      itemSkipRef.current = 0;
      itemHasMoreRef.current = true;
      availableItemsRef.current = [];
      setAvailableItems([]);
      setHasMoreItems(true);
    }

    itemLoadingRef.current = true;
    setIsItemsLoading(true);

    try {
      window.Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnLoadItemsPage', [
        locationCodeRef.current,
        itemSkipRef.current,
        ITEM_PAGE_SIZE,
        searchQuery || '',
      ]);
    } catch (error) {
      itemLoadingRef.current = false;
      setIsItemsLoading(false);
      console.error('Error invoking OnLoadItemsPage:', error);
    }
  };

  const handleItemSearchChange = (nextSearchQuery) => {
    setItemSearchQuery(nextSearchQuery);
    itemSearchQueryRef.current = nextSearchQuery;

    if (itemSearchDebounceRef.current) {
      window.clearTimeout(itemSearchDebounceRef.current);
    }

    itemSearchDebounceRef.current = window.setTimeout(() => {
      requestItemsPage({ reset: true, searchQuery: nextSearchQuery });
    }, 300);
  };

  const handleLoadMoreItems = () => {
    requestItemsPage();
  };

  const handleOpenDraftOrders = () => {
    if (window.Microsoft && window.Microsoft.Dynamics && window.Microsoft.Dynamics.NAV) {
      try {
        window.Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnOpenDraftOrders', [locationCode]);
      } catch (error) {
        console.error('Error invoking OnOpenDraftOrders:', error);
      }
    }
  };

  const handleLocationChange = (newLocationCode) => {
    const selectedLocation = (locationOptions || []).find((location) => location.code === newLocationCode);

    setLocationCode(newLocationCode);
    setLocationName(selectedLocation?.name || '');
    setLastOrderHistory(null);
    setCartItems([]);
    setExpectedDeliveryDate('');
    setReleasedDate('');
    setItemSearchQuery('');
    itemSearchQueryRef.current = '';
    itemSkipRef.current = 0;
    itemHasMoreRef.current = true;
    availableItemsRef.current = [];
    setAvailableItems([]);
    setHasMoreItems(true);

    if (window.Microsoft && window.Microsoft.Dynamics && window.Microsoft.Dynamics.NAV) {
      try {
        window.Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnLocationChanged', [newLocationCode]);
      } catch (error) {
        console.error('Error invoking OnLocationChanged:', error);
      }
    }
  };

  const confirmCheckout = () => {
    if (checkoutCountdown > 0 || isSubmitting) return;

    setShowCheckoutConfirm(false);
    handleCheckout(checkoutMode);
  };

  const handleCheckout = (mode) => {
    if (isSubmitting) return;

    setIsSubmitting(true);
    setProcessingAction(mode === 'draft' ? 'draft' : 'checkout');

    const cartPayload = {
      locationCode: locationCode,
      expectedDeliveryDate: expectedDeliveryDate,
      releasedDate: releasedDate,
      lines: cartItems.map((item) => ({
        itemId: item.id,
        name: item.brandDescription || item.name,
        quantity: Number(item.quantity),
        vendorNo: item.vendorNo,
        brandCode: item.brandCode,
        brandDescription: item.brandDescription,
        uom: item.uom,
        price: item.price,
      })),
    };

    const cartJsonString = JSON.stringify(cartPayload);
    console.log('React POS sending Checkout payload to BC:', cartPayload);

    if (window.Microsoft && window.Microsoft.Dynamics && window.Microsoft.Dynamics.NAV) {
      try {
        const eventName = mode === 'draft' ? 'OnCreateDraftPurchaseOrder' : 'OnCreatePurchaseOrder';
        window.Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(eventName, [cartJsonString]);
      } catch (error) {
        console.error('Error invoking checkout event:', error);
        setIsSubmitting(false);
        setProcessingAction(null);
      }
    } else {
      console.warn('Not running within Business Central Control Add-in environment.');
      setIsSubmitting(false);
      setProcessingAction(null);
      setInfoModalMessage(
        `Local ${mode === 'draft' ? 'Draft' : 'Checkout'} save success. Vendor: ${vendorNo || '-'} | Items: ${cartItems.length}. Payload sent to console.`
      );
      setShowInfoModal(true);
    }
  };

  return (
    <>
      <LayoutSplitter
        leftPanel={
          <div className="flex h-full flex-col">
            <div style={{ flex: 1, minHeight: 0 }}>
              <ItemGrid
                items={availableItems}
                onAddToCart={handleAddToCart}
                title="Market List"
                subtitle="Create purchase orders from the available branded item list."
                searchQuery={itemSearchQuery}
                onSearchChange={handleItemSearchChange}
                onLoadMore={handleLoadMoreItems}
                hasMoreItems={hasMoreItems}
                isLoadingItems={isItemsLoading}
              />
            </div>
          </div>
        }
        rightPanel={
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              height: '100%',
              minHeight: 0,
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'flex-start',
                padding: '6px 12px 6px 12px',
                background: '#fff',
                flexShrink: 0,
              }}
            >
              <div
                style={{
                  display: 'flex',
                  alignItems: 'flex-start',
                  justifyContent: 'flex-end',
                  minWidth: '52px',
                  paddingTop: '2px',
                }}
              >
                <button
                  onClick={handleOpenDraftOrders}
                  style={{
                    position: 'relative',
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: '46px',
                    height: '46px',
                    borderRadius: '9999px',
                    border: '1px solid #cbd5e1',
                    background: '#fff',
                    color: '#0f766e',
                    cursor: 'pointer',
                    boxShadow: '0 6px 18px rgba(15, 23, 42, 0.08)',
                  }}
                  title="Open Draft Orders"
                >
                  <svg
                    className="h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth="1.8"
                    aria-hidden="true"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" d="M14.25 17.25h5.25V9.75a2.25 2.25 0 0 0-2.25-2.25h-1.386a1.5 1.5 0 0 1-1.06-.44l-1.12-1.12a1.5 1.5 0 0 0-1.06-.44H6.75A2.25 2.25 0 0 0 4.5 7.75v9.5a2.25 2.25 0 0 0 2.25 2.25h7.5" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 12.75h3m0 0h3m-3-3v6" />
                  </svg>
                  {draftOrderCount > 0 && (
                    <span
                      style={{
                        position: 'absolute',
                        top: '-4px',
                        right: '-4px',
                        minWidth: '22px',
                        height: '22px',
                        padding: '0 6px',
                        borderRadius: '9999px',
                        background: '#dc2626',
                        color: '#fff',
                        fontSize: '11px',
                        fontWeight: 700,
                        display: 'inline-flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        border: '2px solid #fff',
                      }}
                    >
                      {draftOrderCount}
                    </span>
                  )}
                </button>
              </div>

              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                  minWidth: '220px',
                  flexShrink: 0,
                }}
              >
                <div
                  style={{
                    border: '1px solid #d1d5db',
                    borderRadius: '6px',
                    padding: '4px 10px',
                    background: '#f9fafb',
                    fontSize: '12px',
                    lineHeight: '16px',
                  }}
                >
                  <div style={{ color: '#6b7280', marginBottom: '6px' }}>Location</div>
                  <select
                    value={locationCode}
                    onChange={(e) => handleLocationChange(e.target.value)}
                    style={{
                      width: '100%',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      padding: '6px 8px',
                      fontSize: '13px',
                      color: '#111827',
                      background: '#fff',
                    }}
                  >
                    {locationOptions.length === 0 && <option value="">{locationCode ? `${locationCode}${locationName ? ` - ${locationName}` : ''}` : '-'}</option>}
                    {locationOptions.map((location) => (
                      <option key={location.code} value={location.code}>
                        {location.label || `${location.code}${location.name ? ` - ${location.name}` : ''}`}
                      </option>
                    ))}
                  </select>
                </div>

                <div
                  style={{
                    border: '1px solid #d1d5db',
                    borderRadius: '6px',
                    padding: '8px 10px',
                    background: '#f9fafb',
                    fontSize: '12px',
                    lineHeight: '16px',
                  }}
                >
                  <div style={{ color: '#6b7280', marginBottom: '6px' }}>Need by Date</div>
                  <input
                    type="date"
                    value={expectedDeliveryDate}
                    min={todayString}
                    onChange={(e) => {
                      setExpectedDeliveryDate(e.target.value);
                    }}
                    style={{
                      width: '100%',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      padding: '6px 8px',
                      fontSize: '13px',
                      color: '#111827',
                      background: '#fff',
                    }}
                  />
                </div>

                <button
                  onClick={handleLoadLastOrder}
                  disabled={!lastOrderHistory}
                  style={{
                    border: '1px solid #d1d5db',
                    borderRadius: '6px',
                    padding: '8px 10px',
                    background: lastOrderHistory ? '#eff6ff' : '#f3f4f6',
                    color: lastOrderHistory ? '#1d4ed8' : '#9ca3af',
                    fontSize: '13px',
                    fontWeight: 600,
                    cursor: lastOrderHistory ? 'pointer' : 'not-allowed',
                  }}
                >
                  Load Last Order
                </button>

                {lastOrderHistory && (
                  <div
                    style={{
                      border: '1px solid #dbeafe',
                      borderRadius: '6px',
                      padding: '8px 10px',
                      background: '#f8fbff',
                      fontSize: '12px',
                      lineHeight: '16px',
                      color: '#1f2937',
                    }}
                  >
                    Last saved order: {lastOrderHistory.orderedAt || '-'}
                  </div>
                )}
              </div>
            </div>

            <div style={{ flex: 1, minHeight: 0 }}>
              <CartSidebar
                cartItems={cartItems}
                onUpdateQuantity={handleUpdateQuantity}
                onRemove={handleRemove}
                onCheckout={handleCheckoutClick}
                onAddToDraft={handleAddToDraftClick}
                locationCode={locationCode}
                isSubmitting={isSubmitting}
                processingAction={processingAction}
                orderingDisabled={isOrderingDayDisabled}
                draftOrderingDisabled={isDraftOrderingDayDisabled}
              />
            </div>
          </div>
        }
      />

      {showReleasedDateDialog && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0,0,0,0.4)',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            zIndex: 10000,
          }}
        >
          <div
            style={{
              background: '#fff',
              padding: '24px',
              borderRadius: '12px',
              width: '420px',
              maxWidth: '95vw',
              boxShadow: '0 10px 30px rgba(0,0,0,0.2)',
            }}
          >
            <h3
              style={{
                margin: 0,
                marginBottom: '12px',
                fontSize: '22px',
                fontWeight: 700,
                color: '#111827',
              }}
            >
              Assign Released Date
            </h3>

            <p
              style={{
                margin: 0,
                marginBottom: '16px',
                fontSize: '14px',
                color: '#4b5563',
              }}
            >
              Assign a Released Date:
            </p>

            <input
              type="date"
              value={releasedDate}
              min={todayString}
              max={releasedDateMaxString || undefined}
              onChange={(e) => {
                const nextReleasedDate = e.target.value;

                if (draftReleasedDateMaxDays > 0 && nextReleasedDate !== '' && nextReleasedDate > releasedDateMaxString) {
                  setReleasedDate('');
                  setInfoModalMessage(`Released Date cannot be later than ${releasedDateMaxString}.`);
                  setShowInfoModal(true);
                  return;
                }

                if (nextReleasedDate !== '' && !isAllowedReleasedWeekday(nextReleasedDate)) {
                  setReleasedDate('');
                  setInfoModalMessage('Released Date can only be Monday, Wednesday, or Friday.');
                  setShowInfoModal(true);
                  return;
                }

                setReleasedDate(nextReleasedDate);
              }}
              style={{
                width: '100%',
                border: '1px solid #d1d5db',
                borderRadius: '6px',
                padding: '8px 10px',
                fontSize: '14px',
                color: '#111827',
                background: '#fff',
                boxSizing: 'border-box',
                marginBottom: '16px',
              }}
            />

            <div
              style={{
                display: 'flex',
                justifyContent: 'flex-end',
                gap: '10px',
              }}
            >
              <button
                onClick={() => {
                  setShowReleasedDateDialog(false);
                  setReleasedDate('');
                }}
                style={{
                  padding: '10px 18px',
                  borderRadius: '8px',
                  border: '1px solid #d1d5db',
                  background: '#fff',
                  cursor: 'pointer',
                  fontWeight: 500,
                }}
              >
                Cancel
              </button>

              <button
                onClick={handleReleasedDateConfirm}
                style={{
                  padding: '10px 18px',
                  borderRadius: '8px',
                  border: 'none',
                  background: '#6366f1',
                  color: '#fff',
                  cursor: 'pointer',
                  fontWeight: 600,
                }}
              >
                Confirm Released Date
              </button>
            </div>
          </div>
        </div>
      )}

      {showCheckoutConfirm && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0,0,0,0.4)',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            zIndex: 10000,
          }}
        >
          <div
            style={{
              background: '#fff',
              padding: '24px',
              borderRadius: '12px',
              width: '420px',
              maxWidth: '95vw',
              boxShadow: '0 10px 30px rgba(0,0,0,0.2)',
            }}
          >
            <h3
              style={{
                margin: 0,
                marginBottom: '12px',
                fontSize: '22px',
                fontWeight: 700,
                color: '#111827',
              }}
            >
              {checkoutMode === 'draft' ? 'Confirm Add to Draft' : 'Confirm Checkout'}
            </h3>

            <p
              style={{
                margin: 0,
                fontSize: '14px',
                color: '#4b5563',
              }}
            >
              {checkoutMode === 'draft'
                ? 'Are you sure you want to save this as a draft order?'
                : 'Are you sure you want to save this checkout order in Draft Orders for auto-convert?'}
            </p>

            <div
              style={{
                marginTop: '10px',
                fontSize: '14px',
                color: '#374151',
              }}
            >
              Need by Date: <strong>{expectedDeliveryDate}</strong>
            </div>

              {checkoutMode === 'checkout' && isLateCheckoutCutoffReached && (
                <div
                  style={{
                    marginTop: '10px',
                  fontSize: '13px',
                  color: '#b45309',
                  background: '#fffbeb',
                  border: '1px solid #fcd34d',
                  borderRadius: '8px',
                  padding: '10px 12px',
                  }}
                >
                  Notice: this checkout is already late released.
                </div>
              )}

            <div
              style={{
                display: 'flex',
                justifyContent: 'flex-end',
                gap: '10px',
                marginTop: '20px',
              }}
            >
              <button
                onClick={() => setShowCheckoutConfirm(false)}
                style={{
                  padding: '10px 18px',
                  borderRadius: '8px',
                  border: '1px solid #d1d5db',
                  background: '#fff',
                  cursor: 'pointer',
                  fontWeight: 500,
                }}
              >
                Cancel
              </button>

              <button
                onClick={confirmCheckout}
                disabled={checkoutCountdown > 0 || isSubmitting}
                style={{
                  padding: '10px 18px',
                  borderRadius: '8px',
                  border: 'none',
                  background: checkoutCountdown > 0 || isSubmitting ? '#93c5fd' : '#2563eb',
                  color: '#fff',
                  cursor: checkoutCountdown > 0 || isSubmitting ? 'not-allowed' : 'pointer',
                  fontWeight: 600,
                }}
                >
                {isSubmitting
                  ? checkoutMode === 'draft'
                    ? 'Processing Draft...'
                    : 'Processing Checkout...'
                  : checkoutCountdown > 0
                    ? checkoutMode === 'draft'
                      ? `Yes, Add to Draft (${checkoutCountdown})`
                      : `Yes, Checkout (${checkoutCountdown})`
                    : checkoutMode === 'draft'
                      ? 'Yes, Add to Draft'
                      : 'Yes, Checkout'}
              </button>
            </div>
          </div>
        </div>
      )}

      {showSuccessModal && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0,0,0,0.4)',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            zIndex: 10000,
          }}
        >
          <div
            style={{
              background: '#fff',
              padding: '24px',
              borderRadius: '12px',
              width: '520px',
              maxWidth: '95vw',
              boxShadow: '0 10px 30px rgba(0,0,0,0.2)',
            }}
          >
            <h3
              style={{
                margin: 0,
                marginBottom: '12px',
                fontSize: '22px',
                fontWeight: 700,
                color: '#111827',
              }}
            >
              {createdPOStatus === 'draft'
                ? 'Draft Order Created'
                : createdPOStatus === 'checkout'
                  ? 'Checkout Order Saved'
                  : 'Purchase Order Created'}
            </h3>

            <p
              style={{
                margin: 0,
                fontSize: '14px',
                color: '#4b5563',
              }}
            >
              {createdPOStatus === 'draft'
                ? 'Your draft order was saved successfully in Draft Orders.'
                : createdPOStatus === 'checkout'
                  ? 'Your checkout order was saved successfully in Draft Orders and will be converted automatically.'
                : createdPOStatus === 'open'
                  ? 'Your purchase order was created successfully but remains Open.'
                  : 'Your purchase order was created successfully and released.'}
            </p>

            {createdPONumbers.length > 0 && (
              <div
                style={{
                  marginTop: '16px',
                  padding: '14px',
                  border: '1px solid #e5e7eb',
                  borderRadius: '10px',
                  background: '#f9fafb',
                }}
              >
                <div
                  style={{
                    fontSize: '14px',
                    fontWeight: 600,
                    color: '#374151',
                    marginBottom: '10px',
                  }}
                >
                  {createdPOStatus === 'draft' || createdPOStatus === 'checkout' ? 'Draft Number(s)' : 'PO Number(s)'}
                </div>

                <div
                  style={{
                    display: 'flex',
                    flexWrap: 'wrap',
                    gap: '8px',
                  }}
                >
                  {createdPONumbers.map((poNo) => (
                    <span
                      key={poNo}
                      style={{
                        background: '#dbeafe',
                        color: '#1d4ed8',
                        padding: '6px 12px',
                        borderRadius: '9999px',
                        fontSize: '13px',
                        fontWeight: 600,
                      }}
                    >
                      {poNo}
                    </span>
                  ))}
                </div>
              </div>
            )}

            <div
              style={{
                display: 'flex',
                justifyContent: 'flex-end',
                marginTop: '20px',
              }}
            >
              <button
                onClick={() => setShowSuccessModal(false)}
                style={{
                  padding: '10px 18px',
                  borderRadius: '8px',
                  border: 'none',
                  background: '#2563eb',
                  color: '#fff',
                  cursor: 'pointer',
                  fontWeight: 600,
                }}
              >
                OK
              </button>
            </div>
          </div>
        </div>
      )}

      {showInfoModal && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0,0,0,0.4)',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            zIndex: 10001,
          }}
        >
          <div
            style={{
              background: '#fff',
              padding: '24px',
              borderRadius: '12px',
              width: '420px',
              maxWidth: '95vw',
              boxShadow: '0 10px 30px rgba(0,0,0,0.2)',
            }}
          >
            <h3
              style={{
                margin: 0,
                marginBottom: '12px',
                fontSize: '22px',
                fontWeight: 700,
                color: '#111827',
              }}
            >
              Notice
            </h3>

            <p
              style={{
                margin: 0,
                fontSize: '14px',
                color: '#4b5563',
              }}
            >
              {infoModalMessage}
            </p>

            <div
              style={{
                display: 'flex',
                justifyContent: 'flex-end',
                marginTop: '20px',
              }}
            >
              <button
                onClick={() => setShowInfoModal(false)}
                style={{
                  padding: '10px 18px',
                  borderRadius: '8px',
                  border: 'none',
                  background: '#2563eb',
                  color: '#fff',
                  cursor: 'pointer',
                  fontWeight: 600,
                }}
              >
                OK
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

export default App;


